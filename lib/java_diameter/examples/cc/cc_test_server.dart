import 'dart:io';
// import 'package:diameter/diameter.dart';
// import 'package:diameter/node.dart';

import '../../dk/i1/diameter/avp.dart';
import '../../dk/i1/diameter/avp_grouped.dart';
import '../../dk/i1/diameter/avp_integer32.dart';
import '../../dk/i1/diameter/avp_integer64.dart';
import '../../dk/i1/diameter/avp_unsinged32.dart';
import '../../dk/i1/diameter/avp_utf8_string.dart';
import '../../dk/i1/diameter/node/capability.dart';
import '../../dk/i1/diameter/node/connection_key.dart';
import '../../dk/i1/diameter/node/node_manager.dart';
import '../../dk/i1/diameter/node/node_settings.dart';
import '../../dk/i1/diameter/protocol_constants.dart';
import '../../dk/i1/diameter/utils.dart';

/**
 * A simple Credit-control server that accepts and grants everything
 */
class CcTestServer extends NodeManager {
  CcTestServer(NodeSettings nodeSettings) : super(nodeSettings);

  static Future<void> main(List<String> args) async {
    if (args.length < 2) {
      print("Usage: <host-id> <realm> [<port>]");
      return;
    }

    String hostId = args[0];
    String realm = args[1];
    int port = args.length >= 3 ? int.parse(args[2]) : 3868;

    // Capability configuration
    Capability capability = Capability();
    capability
        .addAuthApp(ProtocolConstants.DIAMETER_APPLICATION_CREDIT_CONTROL);

    NodeSettings nodeSettings;
    try {
      nodeSettings = NodeSettings(
        hostId, realm,
        99999, // vendor-id
        capability,
        port,
        "cc_test_server", 0x01000000,
      );
    } catch (e) {
      print(e.toString());
      return;
    }

    CcTestServer server = CcTestServer(nodeSettings);
    await server.start();

    print("Hit enter to terminate server");
    stdin.readLineSync();

    await server.stop(50); // Stop but allow 50ms graceful shutdown
  }

  @override
  void handleRequest(Message request, ConnectionKey connKey, Peer peer) {
    // This is not the way to do it, but fine for a lean-and-mean test server
    Message answer = Message();
    answer.prepareResponse(request);

    AVP? avp = request.find(ProtocolConstants.DI_SESSION_ID);
    if (avp != null) answer.add(avp);

    node().addOurHostAndRealm(answer);

    avp = request.find(ProtocolConstants.DI_CC_REQUEST_TYPE);
    if (avp == null) {
      answerError(
          answer, connKey, ProtocolConstants.DIAMETER_RESULT_MISSING_AVP, [
        AVPGrouped(ProtocolConstants.DI_FAILED_AVP, [
          AVP(ProtocolConstants.DI_CC_REQUEST_TYPE, []),
        ])
      ]);
      return;
    }

    int ccRequestType = -1;
    try {
      ccRequestType = AVP_Unsigned32(avp).queryValue();
    } catch (e) {}

    if (![
      ProtocolConstants.DI_CC_REQUEST_TYPE_INITIAL_REQUEST,
      ProtocolConstants.DI_CC_REQUEST_TYPE_UPDATE_REQUEST,
      ProtocolConstants.DI_CC_REQUEST_TYPE_TERMINATION_REQUEST,
      ProtocolConstants.DI_CC_REQUEST_TYPE_EVENT_REQUEST
    ].contains(ccRequestType)) {
      answerError(answer, connKey,
          ProtocolConstants.DIAMETER_RESULT_INVALID_AVP_VALUE, [
        AVPGrouped(ProtocolConstants.DI_FAILED_AVP, [avp!])
      ]);
      return;
    }

    // This test server does not support multiple-services-cc
    avp = request.find(ProtocolConstants.DI_MULTIPLE_SERVICES_CREDIT_CONTROL);
    if (avp != null) {
      answerError(answer, connKey,
          ProtocolConstants.DIAMETER_RESULT_INVALID_AVP_VALUE, [
        AVPGrouped(ProtocolConstants.DI_FAILED_AVP, [avp!])
      ]);
      return;
    }

    avp = request.find(ProtocolConstants.DI_MULTIPLE_SERVICES_INDICATOR);
    if (avp != null) {
      int indicator = -1;
      try {
        indicator = AVP_Unsigned32(avp).queryValue();
      } catch (e) {}
      if (indicator !=
          ProtocolConstants
              .DI_MULTIPLE_SERVICES_INDICATOR_MULTIPLE_SERVICES_NOT_SUPPORTED) {
        answerError(answer, connKey,
            ProtocolConstants.DIAMETER_RESULT_INVALID_AVP_VALUE, [
          AVPGrouped(ProtocolConstants.DI_FAILED_AVP, [avp!])
        ]);
        return;
      }
    }

    answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE,
        ProtocolConstants.DIAMETER_RESULT_SUCCESS));

    avp = request.find(ProtocolConstants.DI_AUTH_APPLICATION_ID);
    if (avp != null) answer.add(avp);

    avp = request.find(ProtocolConstants.DI_CC_REQUEST_TYPE);
    if (avp != null) answer.add(avp);

    avp = request.find(ProtocolConstants.DI_CC_REQUEST_NUMBER);
    if (avp != null) answer.add(avp);

    switch (ccRequestType) {
      case ProtocolConstants.DI_CC_REQUEST_TYPE_INITIAL_REQUEST:
      case ProtocolConstants.DI_CC_REQUEST_TYPE_UPDATE_REQUEST:
      case ProtocolConstants.DI_CC_REQUEST_TYPE_TERMINATION_REQUEST:
        avp = request.find(ProtocolConstants.DI_REQUESTED_SERVICE_UNIT);
        if (avp != null) {
          AVP granted = AVP(avp);
          granted.code = ProtocolConstants.DI_GRANTED_SERVICE_UNIT;
          answer.add(granted);
        }
        break;
      case ProtocolConstants.DI_CC_REQUEST_TYPE_EVENT_REQUEST:
        avp = request.find(ProtocolConstants.DI_REQUESTED_ACTION);
        if (avp == null) {
          answerError(
              answer, connKey, ProtocolConstants.DIAMETER_RESULT_MISSING_AVP, [
            AVPGrouped(ProtocolConstants.DI_FAILED_AVP, [
              AVP(ProtocolConstants.DI_REQUESTED_ACTION, []),
            ])
          ]);
          return;
        }

        int requestedAction = -1;
        try {
          requestedAction = AVP_Unsigned32(avp).queryValue();
        } catch (e) {}

        switch (requestedAction) {
          case ProtocolConstants.DI_REQUESTED_ACTION_DIRECT_DEBITING:
            break;
          case ProtocolConstants.DI_REQUESTED_ACTION_REFUND_ACCOUNT:
            break;
          case ProtocolConstants.DI_REQUESTED_ACTION_CHECK_BALANCE:
            answer.add(AVP_Unsigned32(ProtocolConstants.DI_CHECK_BALANCE_RESULT,
                ProtocolConstants.DI_DI_CHECK_BALANCE_RESULT_ENOUGH_CREDIT));
            break;
          case ProtocolConstants.DI_REQUESTED_ACTION_PRICE_ENQUIRY:
            answer.add(AVPGrouped(ProtocolConstants.DI_COST_INFORMATION, [
              AVPGrouped(ProtocolConstants.DI_UNIT_VALUE, [
                AVP_Integer64(ProtocolConstants.DI_VALUE_DIGITS, 4217),
                AVP_Integer32(ProtocolConstants.DI_EXPONENT, -2),
              ]),
              AVP_Unsigned32(ProtocolConstants.DI_CURRENCY_CODE, 208),
              AVP_UTF8String(ProtocolConstants.DI_COST_UNIT, "kanelsnegl"),
            ]));
            break;
          default:
            answerError(answer, connKey,
                ProtocolConstants.DIAMETER_RESULT_INVALID_AVP_VALUE, [
              AVPGrouped(ProtocolConstants.DI_FAILED_AVP, [avp!])
            ]);
            return;
        }
    }

    Utils.setMandatory_RFC3588(answer);

    try {
      answer(answer, connKey);
    } catch (e) {}
  }

  void answerError(Message answer, ConnectionKey connKey, int resultCode,
      List<AVP> errorAvp) {
    answer.hdr.setError(true);
    answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE, resultCode));
    for (AVP avp in errorAvp) {
      answer.add(avp);
    }
    try {
      answer(answer, connKey);
    } catch (e) {}
  }
}
