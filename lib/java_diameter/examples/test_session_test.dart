import 'dart:async';
import 'dart:io';

// Assumed dependencies or classes that need to be defined elsewhere in your project.
// import 'package:diameter/diameter.dart';
// import 'package:diameter/node.dart';
// import 'package:diameter/session.dart';

import '../dk/i1/diameter/node/capability.dart';
import '../dk/i1/diameter/node/node_settings.dart';
import '../dk/i1/diameter/node/peer.dart';
import '../dk/i1/diameter/protocol_constants.dart';
import '../dk/i1/diameter/session/base_session.dart';
import '../dk/i1/diameter/session/session_manager.dart';
import 'test_session.dart';

class TestSessionTest {
  static Future<void> main(List<String> args) async {
    if (args.length != 1) {
      print("Usage: <remote server-name>");
      return;
    }

    // Capability configuration
    Capability capability = Capability()
      ..addAuthApp(ProtocolConstants.DIAMETER_APPLICATION_NASREQ)
      ..addAcctApp(ProtocolConstants.DIAMETER_APPLICATION_NASREQ);

    NodeSettings nodeSettings;
    try {
      nodeSettings = NodeSettings(
        "TestSessionTest.example.net", "example.net",
        99999, // vendor-id
        capability,
        9999, // Port, must be non-zero since we have sessions
        "dk.i1.diameter.session.SessionManager test", 0x01000001,
      );
    } catch (e) {
      print(e.toString());
      return;
    }

    // Define peers
    List<Peer> peers = [
      Peer(args[0]),  // Assuming args[0] is the remote server name
    ];

    // Create Session Manager
    SessionManager sessionManager = SessionManager(nodeSettings, peers);

    // Start session manager
    await sessionManager.start();
    await Future.delayed(Duration(milliseconds: 500));

    // Create BaseSession
    BaseSession session = TestSession(ProtocolConstants.DIAMETER_APPLICATION_NASREQ, sessionManager);

    // Open session
    await session.openSession();
    print("Session state: ${session.state()}");

    // Simulate waiting for some time
    await Future.delayed(Duration(seconds: 100));

    // Print session state after delay
    print("Session state: ${session.state()}");
  }
}
