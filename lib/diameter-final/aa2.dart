import 'dart:typed_data';
import 'dart:convert';
import './diameter_message.dart';

void main() {
  // Sample Authentication Accept Response (AAC)
  final aacResponse = DiameterMessage.fromFields(
    version: 1,
    commandCode: 274, // Command Code for AAC
    applicationId: 4, // Diameter Credit Control Application
    hopByHopId: 12348, // Unique value for this response
    endToEndId: 67893, // Unique value for this response
    flags: 128, // Response message flag
    avpList: [
      AVP(263, 64, 0, ascii.encode("user12345")), // Session-Id
      AVP(263, 64, 0, ascii.encode("user12345")), // Session-Id
      AVP(263, 64, 0, ascii.encode("user12345")), // Session-Id
      AVP(264, 96, 0, ascii.encode("server.com")), // Origin-Host
      AVP(296, 64, 0, ascii.encode("realm.com")), // Origin-Realm
      AVP(258, 64, 0, Uint8List.fromList([0, 0, 0, 4])), // Auth-Application-Id
      AVP(415, 96, 0, Uint8List.fromList([0, 0, 0, 1])), // CC-Request-Number
      AVP(2001, 64, 0,
          Uint8List.fromList([0, 0, 0, 0])), // Result-Code (Success)
      AVP(307, 96, 0, ascii.encode("user@example.com")), // User-Name
      AVP(
          441,
          96,
          0,
          Uint8List.fromList(
              [0, 0, 0, 60])), // Authorization-Lifetime (60 seconds)
    ],
  );

  // Sample Authorization Accept Response (AAR)
  final aarResponse = DiameterMessage.fromFields(
    version: 1,
    commandCode: 275, // Command Code for AAR
    applicationId: 4, // Diameter Credit Control Application
    hopByHopId: 12349, // Unique value for this response
    endToEndId: 67894, // Unique value for this response
    flags: 128, // Response message flag
    avpList: [
      AVP(263, 64, 0, ascii.encode("user12345")), // Session-Id
      AVP(264, 96, 0, ascii.encode("server.com")), // Origin-Host
      AVP(296, 64, 0, ascii.encode("realm.com")), // Origin-Realm
      AVP(258, 64, 0, Uint8List.fromList([0, 0, 0, 4])), // Auth-Application-Id
      AVP(415, 96, 0, Uint8List.fromList([0, 0, 0, 1])), // CC-Request-Number
      AVP(2001, 64, 0,
          Uint8List.fromList([0, 0, 0, 0])), // Result-Code (Success)
      AVP(436, 96, 0,
          Uint8List.fromList([0, 0, 0, 1])), // Granted-Service-Unit (1 unit)
      AVP(
          441,
          96,
          0,
          Uint8List.fromList(
              [0, 0, 0, 60])), // Authorization-Lifetime (60 seconds)
    ],
  );

  // Handle AAC Response
  handleDiameterResponse(aacResponse);

  // Handle AAR Response
  handleDiameterResponse(aarResponse);
}

void handleDiameterResponse(DiameterMessage response) {
  // Check Result-Code for success or failure
  final resultCodeAVP = response.avps.firstWhere((avp) => avp.code == 2001);
  if (resultCodeAVP != null && resultCodeAVP.value[0] == 0) {
    print("Response was successful.");

    // Extract relevant AVPs based on the command (e.g., Authentication or Authorization)
    if (response.commandCode == 274) {
      print("Authentication Accept received.");
      final userNameAVP = response.avps.firstWhere((avp) => avp.code == 307);
      final authLifetimeAVP =
          response.avps.firstWhere((avp) => avp.code == 441);
      print("Authenticated User: ${ascii.decode(userNameAVP.value)}");
      print(
          "Authorization Lifetime: ${ByteData.sublistView(authLifetimeAVP.value).getInt32(0, Endian.big)} seconds");
    } else if (response.commandCode == 275) {
      print("Authorization Accept received.");
      final grantedServiceUnitAVP =
          response.avps.firstWhere((avp) => avp.code == 436);
      print(
          "Granted Service Unit: ${ByteData.sublistView(grantedServiceUnitAVP.value).getInt32(0, Endian.big)} units");
    }
  } else {
    print("Response failed. Result-Code: ${resultCodeAVP?.value}");
  }
}
