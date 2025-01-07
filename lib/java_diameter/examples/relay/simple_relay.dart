import 'dart:io';
import 'package:diameter/diameter.dart';
import 'package:diameter/node.dart';

import '../../dk/i1/diameter/avp_unsinged32.dart';
import '../../dk/i1/diameter/message.dart';
import '../../dk/i1/diameter/node/capability.dart';
import '../../dk/i1/diameter/node/connection_key.dart';
import '../../dk/i1/diameter/node/node_manager.dart';
import '../../dk/i1/diameter/node/node_settings.dart';
import '../../dk/i1/diameter/node/peer.dart';
import '../../dk/i1/diameter/protocol_constants.dart';
import '../../dk/i1/diameter/utils.dart';

/**
 * A simple diameter relay.
 * As start-up arguments it takes a bit of configuration including a list of
 * upstream diameter nodes. This example application shows how NodeManager can
 * handle state and keep track of forwarded requests.
 *
 * It does not have any realm-based routing, but instead simply forwards
 * requests to the first available upstream peer, so it is probably not
 * suitable for production use.
 */
class SimpleRelay extends NodeManager {
  List<Peer> upstreamPeers = [];

  SimpleRelay(NodeSettings nodeSettings) : super(nodeSettings);

  // Reject the request with a specific error
  void rejectRequest(Message request, ConnectionKey connKey, int why) {
    Message answer = Message();
    answer.prepareResponse(request);
    answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE, why));
    Utils.setMandatory_RFC3588(answer);
    try {
      answer(answer, connKey);
    } catch (e) {}
  }

  // Check if the peer is in the list of upstream peers
  bool isUpstreamPeer(Peer peer) {
    for (var p in upstreamPeers) {
      if (p == peer || p == peer) return true;
    }
    return false;
  }

  // Forwarded request state
  static class ForwardedRequestState {
    final ConnectionKey connKey;
    final int hopByHopIdentifier;

    ForwardedRequestState(this.connKey, this.hopByHopIdentifier);
  }

  @override
  void handleRequest(Message request, ConnectionKey connKey, Peer peer) {
    // If destination-host is present, we have to honour that
    AVP? avpDestinationHost = request.find(ProtocolConstants.DI_DESTINATION_HOST);
    if (avpDestinationHost != null) {
      String destinationHost = AVP_UTF8String(avpDestinationHost).queryValue();
      // If it is ourselves...
      if (destinationHost == settings().hostId()) {
        // Since we do not hold any sessions or real state (we are a relay), we can simply reject it
        rejectRequest(request, connKey, ProtocolConstants.DIAMETER_RESULT_COMMAND_UNSUPPORTED);
      } else {
        // Not ourselves
        ConnectionKey? ck;
        try {
          ck = node().findConnection(Peer(destinationHost));
        } catch (e) {}
        if (ck != null) {
          // Forward to peer
          try {
            forwardRequest(request, ck, ForwardedRequestState(connKey, request.hdr.hopByHopIdentifier));
          } catch (e) {
            rejectRequest(request, connKey, ProtocolConstants.DIAMETER_RESULT_UNABLE_TO_DELIVER);
          }
        } else {
          // The destination host could be behind another relay/proxy, but we are too stupid to do intelligent routing
          rejectRequest(request, connKey, ProtocolConstants.DIAMETER_RESULT_UNABLE_TO_DELIVER);
        }
      }
      return;
    }

    if (isUpstreamPeer(peer)) {
      // If it was a request from an upstream host, reject it
      rejectRequest(request, connKey, ProtocolConstants.DIAMETER_RESULT_UNABLE_TO_DELIVER);
    } else {
      // If it is a request from one of the non-upstream peers, forward it to one of the upstream peers
      for (var p in upstreamPeers) {
        ConnectionKey? ck = node().findConnection(p);
        if (ck == null) continue;
        // Forward to peer
        try {
          forwardRequest(request, ck, ForwardedRequestState(connKey, request.hdr.hopByHopIdentifier));
          return;
        } catch (e) {}
      }
      // Could not forward to any of the upstream hosts
      rejectRequest(request, connKey, ProtocolConstants.DIAMETER_RESULT_UNABLE_TO_DELIVER);
    }
  }

  @override
  void handleAnswer(Message answer, ConnectionKey answerConnKey, Object state) {
    // Since we never originate requests ourselves, it is very simple to handle
    ForwardedRequestState frs = state as ForwardedRequestState;
    try {
      answer.hdr.hopByHopIdentifier = frs.hopByHopIdentifier;
      forwardAnswer(answer, frs.connKey);
    } catch (e) {}
  }

  static Future<void> main(List<String> args) async {
    if (args.length < 5) {
      print("Usage: <vendor-id> <host-id> <realm> <port> [upstream-host...]");
      return;
    }

    int vendorId = int.parse(args[0]);
    String hostId = args[1];
    String realm = args[2];
    int port = int.parse(args[3]);

    // Define capability
    Capability capability = Capability();
    capability.addAuthApp(ProtocolConstants.DIAMETER_APPLICATION_RELAY);
    capability.addAcctApp(ProtocolConstants.DIAMETER_APPLICATION_RELAY);

    NodeSettings nodeSettings;
    try {
      nodeSettings = NodeSettings(
        hostId, realm,
        vendorId,
        capability,
        port,
        "simple_relay (DartDiameter)", 0x01000000,
      );
    } catch (e) {
      print(e.toString());
      return;
    }

    SimpleRelay sr = SimpleRelay(nodeSettings);
    await sr.start();

    // Add the upstream hosts as persistent peers
    for (int i = 4; i < args.length; i++) {
      Peer peer = Peer(args[i]);
      sr.upstreamPeers.add(peer);
      sr.node().initiateConnection(peer, true);
    }

    // Wait for connections to be established
    await sr.waitForConnection(150);

    print("Hit enter to terminate relay");
    stdin.readLineSync();

    await sr.stop(50); // Stop but allow 50ms graceful shutdown
  }
}
