import 'dart:async';
import 'dart:io';

// Assumed dependencies or classes that need to be defined elsewhere in your project.
import 'package:diameter/diameter.dart';
import 'package:diameter/node.dart';

import '../../dk/i1/diameter/avp_unsinged32.dart';
import '../../dk/i1/diameter/avp_utf8_string.dart';
import '../../dk/i1/diameter/message.dart';
import '../../dk/i1/diameter/node/capability.dart';
import '../../dk/i1/diameter/node/node_settings.dart';
import '../../dk/i1/diameter/node/peer.dart';
import '../../dk/i1/diameter/node/simple_sync_client.dart';
import '../../dk/i1/diameter/protocol_constants.dart';

class Asr {
  static Future<void> main(List<String> args) async {
    if (args.length != 3) {
      print("Usage: <peer> <auth-app-id> <session-id>");
      return;
    }

    String peer = args[0];
    int authAppId;
    
    if (args[1] == "nasreq") {
      authAppId = ProtocolConstants.DIAMETER_APPLICATION_NASREQ;
    } else if (args[1] == "mobileip") {
      authAppId = ProtocolConstants.DIAMETER_APPLICATION_MOBILEIP;
    } else {
      authAppId = int.parse(args[1]);
    }

    String sessionId = args[2];
    String destHost = args[0];
    String destRealm = destHost.substring(destHost.indexOf('.') + 1);

    // Capability configuration
    Capability capability = Capability()..addAuthApp(authAppId);

    NodeSettings nodeSettings;
    try {
      nodeSettings = NodeSettings(
        "somehost.example.net", "example.net",
        99999, // vendor-id
        capability,
        9999, // Port number (set non-zero)
        "ASR client", 0x01000000,
      );
    } catch (e) {
      print(e.toString());
      return;
    }

    // Define peers
    List<Peer> peers = [Peer(peer)];

    // Create and start SimpleSyncClient
    SimpleSyncClient ssc = SimpleSyncClient(nodeSettings, peers);
    await ssc.start();
    await Future.delayed(Duration(seconds: 2)); // Allow connections to be established.

    // Build ASR Message
    Message asr = Message();
    asr.add(AVP_UTF8String(ProtocolConstants.DI_SESSION_ID, sessionId));
    ssc.node().addOurHostAndRealm(asr);
    asr.add(AVP_UTF8String(ProtocolConstants.DI_DESTINATION_REALM, destRealm));
    asr.add(AVP_UTF8String(ProtocolConstants.DI_DESTINATION_HOST, destHost));
    asr.add(AVP_Unsigned32(ProtocolConstants.DI_AUTH_APPLICATION_ID, authAppId));
    Utils.setMandatory_RFC3588(asr);

    // Send ASR
    Message asa = await ssc.sendRequest(asr);
    if (asa == null) {
      print("No response");
      return;
    }

    // Look at result-code
    AVP? avpResultCode = asa.find(ProtocolConstants.DI_RESULT_CODE);
    if (avpResultCode == null) {
      print("No result-code in response (?)");
      return;
    }

    int resultCode = AVP_Unsigned32(avpResultCode).queryValue();
    if (resultCode != ProtocolConstants.DIAMETER_RESULT_SUCCESS) {
      print("Result-code was not success");
      return;
    }

    await ssc.stop();
  }
}
