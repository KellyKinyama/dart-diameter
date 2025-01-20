import 'dart:convert';
import 'dart:typed_data';
import './diameter_message.dart';

void main() {
  // Create CCR-U (Update Request)
  final ccrUpdate = DiameterMessage.fromFields(
    version: 1,
    commandCode: 272,
    applicationId: 4,
    hopByHopId: 12346, // Replace with unique value
    endToEndId: 67891, // Replace with unique value
    flags: 0,
    avpList: [
      AVP(263, 64, 0, utf8.encode("123456789")), // Session-Id
      AVP(264, 96, 0, ascii.encode("test.com")), // Origin-Host
      AVP(296, 64, 0, ascii.encode("com")), // Origin-Realm
      AVP(258, 64, 0, Uint8List.fromList([0, 0, 0, 4])), // Auth-Application-Id
      AVP(416, 96, 0,
          Uint8List.fromList([0, 0, 0, 2])), // CC-Request-Type (Update)
      AVP(415, 96, 0, Uint8List.fromList([0, 0, 0, 1])), // CC-Request-Number
      AVP(437, 96, 0, Uint8List.fromList([0, 0, 0, 100])) // Used-Service-Unit
    ],
  );

  // Create CCR-T (Termination Request)
  final ccrTerminate = DiameterMessage.fromFields(
    version: 1,
    commandCode: 272,
    applicationId: 4,
    hopByHopId: 12347, // Replace with unique value
    endToEndId: 67892, // Replace with unique value
    flags: 0,
    avpList: [
      AVP(263, 64, 0, ascii.encode("123456789")), // Session-Id
      AVP(264, 96, 0, ascii.encode("test.com")), // Origin-Host
      AVP(296, 64, 0, ascii.encode("com")), // Origin-Realm
      AVP(258, 64, 0, Uint8List.fromList([0, 0, 0, 4])), // Auth-Application-Id
      AVP(416, 96, 0,
          Uint8List.fromList([0, 0, 0, 3])), // CC-Request-Type (Terminate)
      AVP(415, 96, 0, Uint8List.fromList([0, 0, 0, 2])), // CC-Request-Number
      AVP(295, 64, 0, Uint8List.fromList([0, 0, 0, 1])) // Termination-Cause
    ],
  );

  // Encode and print
  print("CCR Update Request:\n${ccrUpdate.encode()}");
  print("CCR Termination Request:\n${ccrTerminate.encode()}");
}


// Explanation
// AVP Details:

// 263 (Session-Id): Maintains the same value across related requests.
// 264 (Origin-Host): Identifies the Diameter node sending the message (same as the initial CCR-I).
// 296 (Origin-Realm): Identifies the administrative domain of the sender.
// 258 (Auth-Application-Id): Specifies the application (4 for Diameter Credit Control).
// 416 (CC-Request-Type): Indicates the request type (2 for Update, 3 for Termination).
// 415 (CC-Request-Number): Incremental sequence number for requests in the same session.
// 437 (Used-Service-Unit): Reports the service units used so far (only in CCR-U).
// 295 (Termination-Cause): Specifies the reason for session termination (only in CCR-T).
// Encoding: The encodeTo() method in the DiameterMessage class ensures proper encoding into a Diameter-compliant byte format.

// Unique IDs: Update the hopByHopId and endToEndId values to ensure uniqueness for each request.