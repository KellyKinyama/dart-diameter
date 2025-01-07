import 'dart:io';

import '../../dk/i1/diameter/avp.dart';
import '../../dk/i1/diameter/avp_unsinged32.dart';
import '../../dk/i1/diameter/message.dart';
import '../../dk/i1/diameter/node/capability.dart';
import '../../dk/i1/diameter/node/connection_key.dart';
import '../../dk/i1/diameter/node/node_manager.dart';
import '../../dk/i1/diameter/node/node_settings.dart';
import '../../dk/i1/diameter/node/peer.dart';
import '../../dk/i1/diameter/protocol_constants.dart';
import '../../dk/i1/diameter/utils.dart';
// import 'package:diameter/diameter.dart';
// import 'package:diameter/node.dart';
// import 'package:diameter/session.dart';

/**
 * A simple Test Session server
 */
class TestSessionServer extends NodeManager {
  TestSessionServer(NodeSettings nodeSettings) : super(nodeSettings);

  static Future<void> main(List<String> args) async {
    if (args.length != 1) {
      print("Usage: <host-id>");
      return;
    }

    // Define capability
    Capability capability = Capability();
    capability.addAuthApp(ProtocolConstants.DIAMETER_APPLICATION_NASREQ);
    capability.addAcctApp(ProtocolConstants.DIAMETER_APPLICATION_NASREQ);

    NodeSettings nodeSettings;
    try {
      nodeSettings = NodeSettings(
        args[0], "example.net",
        99999, // vendor-id
        capability,
        3868,
        "TestSessionServer", 0x01000000,
      );
    } catch (e) {
      print(e.toString());
      return;
    }

    TestSessionServer tss = TestSessionServer(nodeSettings);
    await tss.start();

    print("Hit enter to terminate server");
    stdin.readLineSync();

    await tss.stop();
  }

  @override
  void handleRequest(Message request, ConnectionKey connKey, Peer peer) {
    // This is not the way to do it, but fine for a lean-and-mean test server
    Message answer = Message();
    answer.prepareResponse(request);

    AVP? avpSessionId = request.find(ProtocolConstants.DI_SESSION_ID);
    if (avpSessionId != null) {
      answer.add(avpSessionId);
    }

    answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE, ProtocolConstants.DIAMETER_RESULT_SUCCESS));

    AVP? avpAuthAppId = request.find(ProtocolConstants.DI_AUTH_APPLICATION_ID);
    if (avpAuthAppId != null) {
      answer.add(avpAuthAppId);
    }

    // Switch on the command code
    switch (request.hdr.commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_AA:
        // Uncomment if needed: answer.add(AVP_Unsigned32(ProtocolConstants.DI_AUTHORIZATION_LIFETIME, 60));
        break;
    }

    // Set mandatory RFC3588 fields
    Utils.setMandatory_RFC3588(answer);

    try {
      answer(answer, connKey);
    } catch (e) {}
  }
}
