import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../diameter_message11.dart';
import '../standard_avps/standart_avps.dart';

class CapabilitiesExchangeRequest extends DiameterMessage {
  CapabilitiesExchangeRequest({
    required String originHost,
    required String originRealm,
    required int vendorId,
    required List<int> supportedVendorIds,
    required List<int> authAppIds,
    required List<int> acctAppIds,
  }) : super(
          version: 1,
          length: 0, // Placeholder, will be updated after encoding
          flags: 0x80, // Request flag
          commandCode: 257, // CER command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            VendorIdAVP(vendorId),
            SupportedVendorIdAVP(supportedVendorIds),
            AuthApplicationIdAVP(authAppIds),
            AcctApplicationIdAVP(acctAppIds),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class CapabilitiesExchangeAnswer extends DiameterMessage {
  CapabilitiesExchangeAnswer({
    required String originHost,
    required String originRealm,
    required int resultCode,
  }) : super(
          version: 1,
          length: 0, // Placeholder, will be updated after encoding
          flags: 0x00, // Answer flag
          commandCode: 257, // CEA command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class DeviceWatchdogRequest extends DiameterMessage {
  DeviceWatchdogRequest({
    required String originHost,
    required String originRealm,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x80, // Request flag
          commandCode: 280, // DWR command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class DeviceWatchdogAnswer extends DiameterMessage {
  DeviceWatchdogAnswer({
    required String originHost,
    required String originRealm,
    required int resultCode,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x00, // Answer flag
          commandCode: 280, // DWA command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class DisconnectPeerRequest extends DiameterMessage {
  DisconnectPeerRequest({
    required String originHost,
    required String originRealm,
    required int disconnectCause,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x80, // Request flag
          commandCode: 282, // DPR command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            DisconnectCauseAVP(disconnectCause),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class AccountingRequest extends DiameterMessage {
  AccountingRequest({
    required String originHost,
    required String originRealm,
    required String sessionId,
    required int accountingRecordType,
    required int accountingRecordNumber,
    String? destinationRealm,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x80, // Request flag
          commandCode: 271, // ACR command code
          applicationId: 3, // Accounting application ID
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            SessionIdAVP(sessionId),
            AccountingRecordTypeAVP(accountingRecordType),
            AccountingRecordNumberAVP(accountingRecordNumber),
            if (destinationRealm != null) DestinationRealmAVP(destinationRealm),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class AccountingAnswer extends DiameterMessage {
  AccountingAnswer({
    required String originHost,
    required String originRealm,
    required String sessionId,
    required int resultCode,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x00, // Answer flag
          commandCode: 271, // ACA command code
          applicationId: 3, // Accounting application ID
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            SessionIdAVP(sessionId),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class AuthenticationRequest extends DiameterMessage {
  AuthenticationRequest({
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String userName,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x80, // Request flag
          commandCode: 265, // AAR command code
          applicationId: 1, // Authentication application ID
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            DestinationRealmAVP(destinationRealm),
            UserNameAVP(userName),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class AuthenticationAnswer extends DiameterMessage {
  AuthenticationAnswer({
    required String originHost,
    required String originRealm,
    required int resultCode,
    required String userName,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x00, // Answer flag
          commandCode: 265, // AAA command code
          applicationId: 1, // Authentication application ID
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            UserNameAVP(userName),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class ReAuthRequest extends DiameterMessage {
  ReAuthRequest({
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int reAuthRequestType,
    required String sessionId,
    String? userName,
  }) : super(
          version: 1,
          length: 0, // Placeholder, auto-calculated
          flags: 0x80, // Request flag
          commandCode: 258, // RAR command code
          applicationId: 0, // Default or specific application ID
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            DestinationRealmAVP(destinationRealm),
            ReAuthRequestTypeAVP(reAuthRequestType),
            SessionIdAVP(sessionId),
            if (userName != null) UserNameAVP(userName),
          ],
        );

  ReAuthRequest.fromDecoded(DiameterMessage message)
      : super.fromDecoded(message) {
    _validateMandatoryAvps();
  }

  void _validateMandatoryAvps() {
    if (!hasAvp<SessionIdAVP>()) {
      throw DiameterProtocolException(
        resultCode: ResultCodeAVP.DIAMETER_MISSING_AVP,
        errorMessage: 'Session-Id AVP is missing',
      );
    }
    if (!hasAvp<ReAuthRequestTypeAVP>()) {
      throw DiameterProtocolException(
        resultCode: ResultCodeAVP.DIAMETER_MISSING_AVP,
        errorMessage: 'Re-Auth-Request-Type AVP is missing',
      );
    }
  }

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class ReAuthAnswer extends DiameterMessage {
  ReAuthAnswer({
    required String originHost,
    required String originRealm,
    required int resultCode,
    required String sessionId,
    String? errorMessage,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x00,
          commandCode: 258,
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
            SessionIdAVP(sessionId),
            if (errorMessage != null) ErrorMessageAVP(errorMessage),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class DiameterProtocolException implements Exception {
  final int resultCode;
  final String errorMessage;

  DiameterProtocolException({
    required this.resultCode,
    required this.errorMessage,
  });

  @override
  String toString() =>
      'DiameterProtocolException: $errorMessage (Code: $resultCode)';
}

class CreditControlRequest extends DiameterMessage {
  CreditControlRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required int requestType,
    required int serviceContextId,
    int? requestedAction,
    int? creditControlType,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x80,
          commandCode: 272,
          applicationId: 4, // Credit-Control Application
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            SessionIdAVP(sessionId),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            CCRequestTypeAVP(requestType),
            ServiceContextIdAVP(serviceContextId),
            if (requestedAction != null) RequestedActionAVP(requestedAction),
            if (creditControlType != null) CreditControlTypeAVP(creditControlType),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class CreditControlAnswer extends DiameterMessage {
  CreditControlAnswer({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required int resultCode,
    int? grantedServiceUnit,
    int? usedServiceUnit,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x00,
          commandCode: 272,
          applicationId: 4,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            SessionIdAVP(sessionId),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
            if (grantedServiceUnit != null) GrantedServiceUnitAVP(grantedServiceUnit),
            if (usedServiceUnit != null) UsedServiceUnitAVP(usedServiceUnit),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class AbortSessionRequest extends DiameterMessage {
  AbortSessionRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    String? destinationHost,
    String? destinationRealm,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x80,
          commandCode: 274,
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            SessionIdAVP(sessionId),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            if (destinationHost != null) DestinationHostAVP(destinationHost),
            if (destinationRealm != null) DestinationRealmAVP(destinationRealm),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class AbortSessionAnswer extends DiameterMessage {
  AbortSessionAnswer({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required int resultCode,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x00,
          commandCode: 274,
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            SessionIdAVP(sessionId),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class SessionTerminationRequest extends DiameterMessage {
  SessionTerminationRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required int terminationCause,
    String? destinationHost,
    String? destinationRealm,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x80,
          commandCode: 275,
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            SessionIdAVP(sessionId),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            TerminationCauseAVP(terminationCause),
            if (destinationHost != null) DestinationHostAVP(destinationHost),
            if (destinationRealm != null) DestinationRealmAVP(destinationRealm),
          ],
        );
}

class UserNameRequest extends DiameterMessage {
  UserNameRequest({
    required String userName,
    required String originHost,
    required String originRealm,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x80,
          commandCode: 300, // Example command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            UserNameAVP(userName),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}


class UserNameAnswer extends DiameterMessage {
  UserNameAnswer({
    required String userName,
    required String originHost,
    required String originRealm,
    required int resultCode,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x00,
          commandCode: 300, // Same command code as UNR
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            UserNameAVP(userName),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

// class AccountingRequest extends DiameterMessage {
//   AccountingRequest({
//     required String sessionId,
//     required String originHost,
//     required String originRealm,
//     required int accountingRecordType,
//     required int accountingRecordNumber,
//   }) : super(
//           version: 1,
//           length: 0,
//           flags: 0x80,
//           commandCode: 271, // Accounting Request command code
//           applicationId: 4, // Accounting Application ID
//           hopByHopId: _generateHopByHopId(),
//           endToEndId: _generateEndToEndId(),
//           avps: [
//             SessionIdAVP(sessionId),
//             OriginHostAVP(originHost),
//             OriginRealmAVP(originRealm),
//             AccountingRecordTypeAVP(accountingRecordType),
//             AccountingRecordNumberAVP(accountingRecordNumber),
//           ],
//         );

//   static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
//   static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
// }

class DeviceErrorRequest extends DiameterMessage {
  DeviceErrorRequest({
    required String originHost,
    required String originRealm,
    required String errorDetails,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x80,
          commandCode: 300, // DER command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ErrorDetailsAVP(errorDetails),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class DeviceErrorAnswer extends DiameterMessage {
  DeviceErrorAnswer({
    required String originHost,
    required String originRealm,
    required int resultCode,
    String? errorMessage,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x00,
          commandCode: 300, // DEA command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
            if (errorMessage != null) ErrorMessageAVP(errorMessage),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class TerminationRequest extends DiameterMessage {
  TerminationRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x80,
          commandCode: 320, // TER command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            SessionIdAVP(sessionId),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

class TerminationAnswer extends DiameterMessage {
  TerminationAnswer({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required int resultCode,
  }) : super(
          version: 1,
          length: 0,
          flags: 0x00,
          commandCode: 320, // TEA command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            SessionIdAVP(sessionId),
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}

