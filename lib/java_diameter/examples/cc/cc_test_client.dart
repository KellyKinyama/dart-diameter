import 'dart:async';
import 'dart:io';

// Assumed dependencies or classes that need to be defined elsewhere in your project.
import 'package:dart_diameter/java_diameter/dk/i1/diameter/avp_unsinged32.dart';
// import 'package:diameter/diameter.dart';
// import 'package:diameter/node.dart';

import '../../dk/i1/diameter/avp.dart';
import '../../dk/i1/diameter/avp_grouped.dart';
import '../../dk/i1/diameter/avp_time.dart';
import '../../dk/i1/diameter/avp_unsigned64.dart';
import '../../dk/i1/diameter/avp_utf8_string.dart';
import '../../dk/i1/diameter/message.dart';
import '../../dk/i1/diameter/node/capability.dart';
import '../../dk/i1/diameter/node/node_settings.dart';
import '../../dk/i1/diameter/node/peer.dart';
import '../../dk/i1/diameter/node/simple_sync_client.dart';
import '../../dk/i1/diameter/protocol_constants.dart';
import '../../dk/i1/diameter/utils.dart';

class CcTestClient {
  static Future<void> main(List<String> args) async {
    if (args.length != 4) {
      print("Usage: <host-id> <realm> <peer> <peer-port>");
      return;
    }

    String hostId = args[0];
    String realm = args[1];
    String destHost = args[2];
    int destPort = int.parse(args[3]);

    // Capability configuration
    Capability capability = Capability()
      ..addAuthApp(ProtocolConstants.DIAMETER_APPLICATION_CREDIT_CONTROL);

    NodeSettings nodeSettings;
    try {
      nodeSettings = NodeSettings(
        hostId, realm,
        99999, // vendor-id
        capability,
        0, // Port can be 0 when not specified
        "cc_test_client", 0x01000000,
      );
    } catch (e) {
      print(e.toString());
      return;
    }

    // Define peers
    List<Peer> peers = [Peer(destHost, destPort)];

    // Create and start SimpleSyncClient
    SimpleSyncClient ssc = SimpleSyncClient(nodeSettings, peers);
    await ssc.start();
    await ssc.waitForConnection(); // Allow connection to be established.

    // Build Credit-Control Request (CCR)
    Message ccr = Message();
    ccr.hdr.commandCode = ProtocolConstants.DIAMETER_COMMAND_CC;
    ccr.hdr.applicationId =
        ProtocolConstants.DIAMETER_APPLICATION_CREDIT_CONTROL;
    ccr.hdr.setRequest(true);
    ccr.hdr.setProxiable(true);

    // < Session-Id >
    ccr.add(AVP_UTF8String(
        ProtocolConstants.DI_SESSION_ID, ssc.node().makeNewSessionId()));

    // { Origin-Host }
    // { Origin-Realm }
    ssc.node().addOurHostAndRealm(ccr);

    // { Destination-Realm }
    ccr.add(
        AVP_UTF8String(ProtocolConstants.DI_DESTINATION_REALM, "example.net"));

    // { Auth-Application-Id }
    ccr.add(AVP_Unsigned32(ProtocolConstants.DI_AUTH_APPLICATION_ID,
        ProtocolConstants.DIAMETER_APPLICATION_CREDIT_CONTROL));

    // { Service-Context-Id }
    ccr.add(AVP_UTF8String(
        ProtocolConstants.DI_SERVICE_CONTEXT_ID, "cc_test@example.net"));

    // { CC-Request-Type }
    ccr.add(AVP_Unsigned32(ProtocolConstants.DI_CC_REQUEST_TYPE,
        ProtocolConstants.DI_CC_REQUEST_TYPE_EVENT_REQUEST));

    // { CC-Request-Number }
    ccr.add(AVP_Unsigned32(ProtocolConstants.DI_CC_REQUEST_NUMBER, 0));

    // [ Destination-Host ]
    // [ User-Name ]
    ccr.add(AVP_UTF8String(ProtocolConstants.DI_USER_NAME, "user@example.net"));

    // [ Origin-State-Id ]
    ccr.add(AVP_Unsigned32(
        ProtocolConstants.DI_ORIGIN_STATE_ID, ssc.node().stateId()));

    // [ Event-Timestamp ]
    ccr.add(AVP_Time(ProtocolConstants.DI_EVENT_TIMESTAMP,
        (DateTime.now().millisecondsSinceEpoch ~/ 1000)));

    // [ Requested-Service-Unit ]
    ccr.add(AVPGrouped(ProtocolConstants.DI_REQUESTED_SERVICE_UNIT, [
      AVP_Unsigned64(ProtocolConstants.DI_CC_SERVICE_SPECIFIC_UNITS, 42),
    ]));

    // [ Requested-Action ]
    ccr.add(AVP_Unsigned32(ProtocolConstants.DI_REQUESTED_ACTION,
        ProtocolConstants.DI_REQUESTED_ACTION_DIRECT_DEBITING));

    // [ Service-Parameter-Info ]
    ccr.add(AVPGrouped(ProtocolConstants.DI_SERVICE_PARAMETER_INFO, [
      AVP_Unsigned32(ProtocolConstants.DI_SERVICE_PARAMETER_TYPE, 42),
      AVP_UTF8String(
          ProtocolConstants.DI_SERVICE_PARAMETER_VALUE, "Hovercraft"),
    ]));

    // Set mandatory RFC3588 and RFC4006 AVPs
    Utils.setMandatory_RFC3588(ccr);
    Utils.setMandatory_RFC4006(ccr);

    // Send CCR request
    Message cca = await ssc.sendRequest(ccr);

    // Check the result code
    if (cca == null) {
      print("No response");
      return;
    }

    AVP? resultCodeAvp = cca.find(ProtocolConstants.DI_RESULT_CODE);
    if (resultCodeAvp == null) {
      print("No result code");
      return;
    }

    try {
      AVP_Unsigned32 resultCodeU32 = AVP_Unsigned32(resultCodeAvp);
      int resultCode = resultCodeU32.queryValue();

      switch (resultCode) {
        case ProtocolConstants.DIAMETER_RESULT_SUCCESS:
          print("Success");
          break;
        case ProtocolConstants.DIAMETER_RESULT_END_USER_SERVICE_DENIED:
          print("End user service denied");
          break;
        case ProtocolConstants.DIAMETER_RESULT_CREDIT_CONTROL_NOT_APPLICABLE:
          print("Credit-control not applicable");
          break;
        case ProtocolConstants.DIAMETER_RESULT_CREDIT_LIMIT_REACHED:
          print("Credit-limit reached");
          break;
        case ProtocolConstants.DIAMETER_RESULT_USER_UNKNOWN:
          print("User unknown");
          break;
        case ProtocolConstants.DIAMETER_RESULT_RATING_FAILED:
          print("Rating failed");
          break;
        default:
          if (resultCode >= 1000 && resultCode < 1999) {
            print("Informational: $resultCode");
          } else if (resultCode >= 2000 && resultCode < 2999) {
            print("Success: $resultCode");
          } else if (resultCode >= 3000 && resultCode < 3999) {
            print("Protocol error: $resultCode");
          } else if (resultCode >= 4000 && resultCode < 4999) {
            print("Transient failure: $resultCode");
          } else if (resultCode >= 5000 && resultCode < 5999) {
            print("Permanent failure: $resultCode");
          } else {
            print("(unknown error class): $resultCode");
          }
      }
    } catch (e) {
      print("Result code was ill-formed");
      return;
    }

    // Stop the stack
    await ssc.stop();
  }
}
