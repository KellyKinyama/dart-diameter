import 'dart:convert';
import 'dart:typed_data';

import './diameter_message.dart';
import 'diameter_client.dart';

class CreditControlRequest {
  DiameterMessage createCCR({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int requestType,
    required int requestNumber,
    int applicationId = 4, // Default to Credit-Control Application
  }) {
    return DiameterMessage.fromFields(
      version: 1,
      flags: 128, // Indicates a request
      commandCode: 272, // CCR
      applicationId: applicationId,
      hopByHopId: generateUniqueId(),
      endToEndId: generateUniqueId(),
      avpList: [
        AVP(263, 64, sessionId.length + 8,
            utf8.encode(sessionId)), // Session-Id
        AVP(264, 64, originHost.length + 8,
            utf8.encode(originHost)), // Origin-Host
        AVP(296, 64, originRealm.length + 8,
            utf8.encode(originRealm)), // Origin-Realm
        AVP(283, 64, destinationRealm.length + 8,
            utf8.encode(destinationRealm)), // Destination-Realm
        AVP(
            258,
            64,
            12,
            Uint8List(4)
              ..buffer
                  .asByteData()
                  .setUint32(0, applicationId)), // Auth-Application-Id
        AVP(
            416,
            64,
            12,
            Uint8List(4)
              ..buffer
                  .asByteData()
                  .setUint32(0, requestType)), // CC-Request-Type
        AVP(
            415,
            64,
            12,
            Uint8List(4)
              ..buffer
                  .asByteData()
                  .setUint32(0, requestNumber)), // CC-Request-Number
        // Add more AVPs like Requested-Service-Unit if needed
      ],
    );
  }

  int generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
  }
}

void main() {
  final client = DiameterClient('127.0.0.1', 3868);
  final ccrCreator = CreditControlRequest();

  final ccr = ccrCreator.createCCR(
    sessionId: '123456789',
    originHost: 'client.example.com',
    originRealm: 'example.com',
    destinationRealm: 'server.example.com',
    requestType: 1, // Initial Request
    requestNumber: 0,
  );

  client.sendRequestWithMessage(ccr);
}
