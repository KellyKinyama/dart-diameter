import 'dart:io';
import 'dart:typed_data';

import '../../avp.dart';
import '../../header.dart';
import '../../message.dart';
import 'ccr.dart';

class DiameterCreditControlServer {
  final String serverAddress;
  final int serverPort;

  DiameterCreditControlServer(
      {required this.serverAddress, required this.serverPort});

  // Handle incoming CCR and respond with CCA
  Future<void> handleCreditControlRequest(Uint8List data) async {
    final request = DiameterMessage.decode(data);
    print("Received CCR with Command Code: ${request.header.commandCode}");

    // Process CCR and create CCA
    final header = DiameterHeader(
      version: request.header.version,
      commandFlags: 0x80, // Response flag
      commandCode: 272, // Credit Control Answer (CCA)
      applicationId: 4, // Credit-Control application ID
      hopByHopId: request.header.hopByHopId,
      endToEndId: request.header.endToEndId,
    );

    // Example AVPs for credit control
    final ccRequestTypeAvp = DiameterAVP.ccRequestTypeAvp(1); // INITIAL_REQUEST
    final ccRequestNumberAvp = DiameterAVP.ccRequestNumberAvp(1234);
    final balanceAvp = DiameterAVP.balanceAmountAvp(1000); // Example balance

    final responseMessage = DiameterMessage(
      header: header,
      avps: [ccRequestTypeAvp, ccRequestNumberAvp, balanceAvp],
    );

    final encodedResponse = responseMessage.encode();
    await _sendResponse(encodedResponse);
  }

  // Send the CCA response
  Future<void> _sendResponse(Uint8List response) async {
    final socket = await Socket.connect(serverAddress, serverPort);
    socket.add(response);
    print("Sent CCA response: $response");
    socket.close();
  }
}

void main() async {
  final server =
      DiameterCreditControlServer(serverAddress: '127.0.0.1', serverPort: 3868);

  // Create a Credit Control Request (CCR)
  final header = DiameterHeader(
    version: 1,
    commandFlags: 0x80, // Request flag
    commandCode: 272, // Credit Control Request (CCR)
    applicationId: 4, // Credit-Control application ID
    hopByHopId: 1234,
    endToEndId: 5678,
  );

  final ccRequestTypeAvp = DiameterAVP.ccRequestTypeAvp(1); // INITIAL_REQUEST
  final ccRequestNumberAvp = DiameterAVP.ccRequestNumberAvp(1234);
  final requestedActionAvp =
      DiameterAVP.requestedActionAvp(1); // INITIAL_BALANCE

  final ccr = CreditControlRequest(
    header: header,
    avps: [ccRequestTypeAvp, ccRequestNumberAvp, requestedActionAvp],
  );

  final rawCCR = ccr.encode();
  await server.handleCreditControlRequest(rawCCR);
}
