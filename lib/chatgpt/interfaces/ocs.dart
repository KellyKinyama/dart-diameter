import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import '../avp.dart';
import '../header.dart';
import '../message.dart';

class DiameterOCSInterface {
  final String ocsServerAddress;
  final int ocsServerPort;

  DiameterOCSInterface(
      {required this.ocsServerAddress, required this.ocsServerPort});

  /// Handles the reception of a Credit Control Request (CCR)
  Future<void> handleCreditControlRequest(Uint8List data) async {
    try {
      final request = DiameterMessage.decode(data);
      print(
          "Received Credit Control Request (CCR): ${request.header.commandCode}");

      // Process the Credit Control Request (CCR)
      // For simplicity, assume the request is valid and a credit check is successful.

      // Create Credit Control Answer (CCA) with appropriate credit information
      final header = DiameterHeader(
        version: request.header.version,
        commandFlags: 0x80, // Response flag
        commandCode: 272, // Credit Control Answer (CCA)
        applicationId: 4, // Credit-Control application ID
        hopByHopId: request.header.hopByHopId,
        endToEndId: request.header.endToEndId,
      );

      // Example AVPs for credit allocation and response
      final creditLimitAvp =
          DiameterAVP.integerAVP(413, 1000); // Example AVP for credit limit
      final balanceAvp =
          DiameterAVP.integerAVP(444, 500); // Example AVP for current balance

      // Respond with the Credit Control Answer (CCA)
      final responseMessage =
          DiameterMessage(header: header, avps: [creditLimitAvp, balanceAvp]);
      final encodedResponse = responseMessage.encode();
      await _sendResponseToClient(encodedResponse);
    } catch (e) {
      print("Error handling Credit Control Request (CCR): $e");
    }
  }

  /// Sends the Credit Control Answer (CCA) back to the client
  Future<void> _sendResponseToClient(Uint8List response) async {
    try {
      final socket = await Socket.connect(ocsServerAddress, ocsServerPort);
      socket.add(response);
      print("Sent Credit Control Answer (CCA) to client: $response");
      socket.close();
    } catch (e) {
      print("Error sending Credit Control Answer (CCA): $e");
    }
  }

  /// Handles Event-Request (EAR) for reporting usage events (e.g., data usage)
  Future<void> handleEventRequest(Uint8List data) async {
    try {
      final request = DiameterMessage.decode(data);
      print("Received Event-Request (EAR): ${request.header.commandCode}");

      // Process the Event-Request and report usage
      // Example event: Data usage is reported, and credit is adjusted.

      // Create Event-Answer (EAA) with event results
      final header = DiameterHeader(
        version: request.header.version,
        commandFlags: 0x80, // Response flag
        commandCode: 274, // Event-Answer (EAA)
        applicationId: 4, // Credit-Control application ID
        hopByHopId: request.header.hopByHopId,
        endToEndId: request.header.endToEndId,
      );

      // Example AVP for updated credit after usage
      final updatedBalanceAvp =
          DiameterAVP.integerAVP(444, 400); // Updated balance after usage

      // Respond with the Event-Answer (EAA)
      final responseMessage =
          DiameterMessage(header: header, avps: [updatedBalanceAvp]);
      final encodedResponse = responseMessage.encode();
      await _sendResponseToClient(encodedResponse);
    } catch (e) {
      print("Error handling Event-Request (EAR): $e");
    }
  }
}

void main() async {
  final ocsInterface = DiameterOCSInterface(
    ocsServerAddress: "192.168.1.100",
    ocsServerPort: 3868,
  );

  // Simulating receiving a Credit Control Request (CCR)
  final exampleCCR = DiameterMessage(
    header: DiameterHeader(
      version: 1,
      commandFlags: 0x80,
      commandCode: 272, // Credit Control Request (CCR)
      applicationId: 4, // Credit-Control application ID
      hopByHopId: 1234,
      endToEndId: 5678,
    ),
    avps: [DiameterAVP.integerAVP(413, 1000)], // Requesting credit
  );

  final rawData = exampleCCR.encode();
  await ocsInterface.handleCreditControlRequest(rawData);

  // Simulating receiving an Event-Request (EAR)
  final exampleEAR = DiameterMessage(
    header: DiameterHeader(
      version: 1,
      commandFlags: 0x80,
      commandCode: 274, // Event-Request (EAR)
      applicationId: 4, // Credit-Control application ID
      hopByHopId: 1234,
      endToEndId: 5678,
    ),
    avps: [DiameterAVP.integerAVP(500, 100)], // Event report (e.g., data usage)
  );

  final eventData = exampleEAR.encode();
  await ocsInterface.handleEventRequest(eventData);
}
