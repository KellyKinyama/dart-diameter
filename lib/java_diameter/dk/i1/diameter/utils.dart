import 'avp.dart';
import 'avp_grouped.dart';
import 'message.dart';
import 'protocol_constants.dart';

/// A mishmash of handy methods
class Utils {
  Utils._(); // Prevent instantiation

  static const List<int> emptyArray = [];

  static bool contains(List<int> list, int value) {
    return list.contains(value);
  }

  // static bool setMandatory(
  //     AVP avp, List<int> codes, List<int> groupedAvpCodes) {
  //   bool modified = false;
  //   if (avp.vendorId == 0 && contains(groupedAvpCodes, avp.code)) {
  //     try {
  //       final AVPGrouped avpGrouped = AVPGrouped(avp);
  //       final avpGroupedAVPs = avpGrouped.queryAVPs();

  //       for (final avpGAvp in avpGroupedAVPs) {
  //         modified = setMandatory(avpGAvp, codes, groupedAvpCodes) || modified;
  //       }

  //       bool anyMandatory =
  //           avpGroupedAVPs.any((avpGAvp) => avpGAvp.isMandatory());
  //       if (anyMandatory && !avp.isMandatory()) {
  //         avpGrouped.setMandatory(true);
  //         modified = true;
  //       }

  //       if (modified) {
  //         avpGrouped.setAVPs(avpGroupedAVPs);
  //         avp.inlineShallowReplace(avpGrouped);
  //       }
  //     } on InvalidAVPLengthException {
  //       // Not grouped - ignored
  //     }
  //   }

  //   if (!avp.isMandatory()) {
  //     if (avp.vendorId == 0 && contains(codes, avp.code)) {
  //       avp.setMandatory(true);
  //       modified = true;
  //     }
  //   }

  //   return modified;
  // }

  // static void setMandatory(Iterable<AVP> avps, List<int> codes,
  //     [List<int> groupedAvpCodes = emptyArray]) {
  //   for (final avp in avps) {
  //     setMandatory(avp, codes, groupedAvpCodes);
  //   }
  // }

  static void setMandatoryWithCollection(Iterable<AVP> avps, Set<int> codes) {
    for (final avp in avps) {
      if (codes.contains(avp.code) && avp.vendorId == 0) {
        avp.setMandatory(true);
      }
    }
  }

  static void setMandatoryForMessage(Message msg, List<int> codes,
      [List<int> groupedAvpCodes = emptyArray]) {
    //setMandatory(msg.avps, codes, groupedAvpCodes);
  }

  static const List<int> rfc3588GroupedAVPs = [
    ProtocolConstants.DI_E2E_SEQUENCE_AVP,
    ProtocolConstants.DI_EXPERIMENTAL_RESULT,
    ProtocolConstants.DI_FAILED_AVP,
    ProtocolConstants.DI_PROXY_INFO,
    ProtocolConstants.DI_VENDOR_SPECIFIC_APPLICATION_ID
  ];

  static const List<int> rfc3588MandatoryCodes = [
    // Add the specific RFC3588 mandatory codes
  ];

  /// The AVP codes of the AVPs listen in RFC3588 section 4.5 that must be mandatory
  static const List<int> rfc3588_mandatory_codes = [
    ProtocolConstants.DI_ACCOUNTING_REALTIME_REQUIRED,
    ProtocolConstants.DI_ACCOUNTING_RECORD_NUMBER,
    ProtocolConstants.DI_ACCOUNTING_RECORD_TYPE,
    ProtocolConstants.DI_ACCOUNTING_SESSION_ID,
    ProtocolConstants.DI_ACCOUNTING_SUB_SESSION_ID,
    ProtocolConstants.DI_ACCT_APPLICATION_ID,
    ProtocolConstants.DI_ACCT_INTERIM_INTERVAL,
    ProtocolConstants.DI_ACCT_MULTI_SESSION_ID,
    ProtocolConstants.DI_AUTHORIZATION_LIFETIME,
    ProtocolConstants.DI_AUTH_APPLICATION_ID,
    ProtocolConstants.DI_AUTH_GRACE_PERIOD,
    ProtocolConstants.DI_AUTH_REQUEST_TYPE,
    ProtocolConstants.DI_AUTH_SESSION_STATE,
    ProtocolConstants.DI_CLASS,
    ProtocolConstants.DI_DESTINATION_HOST,
    ProtocolConstants.DI_DESTINATION_REALM,
    ProtocolConstants.DI_DISCONNECT_CAUSE,
    ProtocolConstants.DI_E2E_SEQUENCE_AVP,
    ProtocolConstants.DI_EVENT_TIMESTAMP,
    ProtocolConstants.DI_EXPERIMENTAL_RESULT,
    ProtocolConstants.DI_EXPERIMENTAL_RESULT_CODE,
    ProtocolConstants.DI_FAILED_AVP,
    ProtocolConstants.DI_HOST_IP_ADDRESS,
    ProtocolConstants.DI_INBAND_SECURITY_ID,
    ProtocolConstants.DI_MULTI_ROUND_TIME_OUT,
    ProtocolConstants.DI_ORIGIN_HOST,
    ProtocolConstants.DI_ORIGIN_REALM,
    ProtocolConstants.DI_ORIGIN_STATE_ID,
    ProtocolConstants.DI_PROXY_HOST,
    ProtocolConstants.DI_PROXY_INFO,
    ProtocolConstants.DI_PROXY_STATE,
    ProtocolConstants.DI_REDIRECT_HOST,
    ProtocolConstants.DI_REDIRECT_HOST_USAGE,
    ProtocolConstants.DI_REDIRECT_MAX_CACHE_TIME,
    ProtocolConstants.DI_RESULT_CODE,
    ProtocolConstants.DI_RE_AUTH_REQUEST_TYPE,
    ProtocolConstants.DI_ROUTE_RECORD,
    ProtocolConstants.DI_SESSION_BINDING,
    ProtocolConstants.DI_SESSION_ID,
    ProtocolConstants.DI_SESSION_SERVER_FAILOVER,
    ProtocolConstants.DI_SESSION_TIMEOUT,
    ProtocolConstants.DI_SUPPORTED_VENDOR_ID,
    ProtocolConstants.DI_TERMINATION_CAUSE,
    ProtocolConstants.DI_USER_NAME,
    ProtocolConstants.DI_VENDOR_ID,
    ProtocolConstants.DI_VENDOR_SPECIFIC_APPLICATION_ID
  ];

  /// List of AVPs that are grouped according to RFC3588 section 4.5
  ///@since 0.9.5
  static const List<int> rfc3588_grouped_avps = [
    ProtocolConstants.DI_E2E_SEQUENCE_AVP,
    ProtocolConstants.DI_EXPERIMENTAL_RESULT,
    ProtocolConstants.DI_FAILED_AVP,
    ProtocolConstants.DI_PROXY_INFO,
    ProtocolConstants.DI_VENDOR_SPECIFIC_APPLICATION_ID
  ];

  static void setMandatoryRFC3588(Iterable<AVP> avps) {
    //setMandatory(avps, rfc3588MandatoryCodes, rfc3588GroupedAVPs);
  }

  static void setMandatoryRFC3588ForMessage(Message msg) {
    setMandatoryForMessage(msg, rfc3588MandatoryCodes, rfc3588GroupedAVPs);
  }

  static const List<int> rfc4006MandatoryCodes = [
    // Add the specific RFC4006 mandatory codes
  ];

  static const List<int> rfc4006GroupedAVPs = [
    // Add the specific RFC4006 grouped AVPs
  ];

  static void setMandatoryRFC4006(Iterable<AVP> avps) {
    // setMandatory(avps, rfc4006MandatoryCodes, rfc4006GroupedAVPs);
  }

  static void setMandatoryRFC4006ForMessage(Message msg) {
    setMandatoryForMessage(msg, rfc4006MandatoryCodes, rfc4006GroupedAVPs);
  }

  static void copyProxyInfo(Message from, Message to) {
    for (final avp in from.subset(ProtocolConstants.DI_PROXY_INFO)) {
      to.add(AVP.copy(avp));
    }
  }
}

/// Mock AVP class

/// Mock AVPGrouped class
// class AVPGrouped extends AVP {
//   AVPGrouped(AVP avp) : super(avp.code, avp.vendorId, avp.mandatory);

//   List<AVP> queryAVPs() {
//     // Implementation to return grouped AVPs
//     return [];
//   }

//   void setAVPs(List<AVP> avps) {
//     // Implementation to set grouped AVPs
//   }
// }

/// Mock InvalidAVPLengthException class
// class InvalidAVPLengthException implements Exception {
//   InvalidAVPLengthException(AVP a);
// }
