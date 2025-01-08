import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'avp.dart';
import 'header.dart';
import 'message.dart';

class DiameterRedirectAgent {
  final String address;
  final int port;
  final String redirectAddress;
  final int redirectPort;

  DiameterRedirectAgent({
    required this.address,
    required this.port,
    required this.redirectAddress,
    required this.redirectPort,
  });

  /// Starts the Diameter Redirect Agent, listening for client connections
  Future<void> start() async {
    final server = await ServerSocket.bind(address, port);
    print("Diameter Redirect Agent started on $address:$port");

    server.listen((Socket client) {
      print("New connection from ${client.remoteAddress}:${client.remotePort}");
      client.listen(
        (data) => _handleRequest(data, client),
        onError: (error) => _handleError(error, client),
        onDone: () => _handleDone(client),
        cancelOnError: true, // Automatically cancel on error
      );
    });
  }

  /// Handles incoming requests and sends a redirect response
  void _handleRequest(Uint8List data, Socket client) {
    try {
      print("Received data from client: $data");

      // Decode the incoming Diameter message
      final message = DiameterMessage.decode(data);
      print("Decoded DiameterMessage:");
      print("  Version: ${message.header.version}");
      print("  Command Code: ${message.header.commandCode}");
      print("  Application ID: ${message.header.applicationId}");
      print("  Hop-by-Hop ID: ${message.header.hopByHopId}");
      print("  End-to-End ID: ${message.header.endToEndId}");
      print("  AVP Count: ${message.avps.length}");

      // Generate the Redirect AVP
      final redirectAVP = DiameterAVP.redirectAVP(
        1, // Example AVP code for redirect
        redirectAddress, // New address where the request should be forwarded
        redirectPort, // Port for the new address
      );

      // Create the redirect response message
      final responseHeader = DiameterHeader(
        version: message.header.version,
        commandFlags: 0x00, // Response flag
        commandCode: message.header.commandCode,
        applicationId: message.header.applicationId,
        hopByHopId: message.header.hopByHopId,
        endToEndId: message.header.endToEndId,
      );

      final responseMessage = DiameterMessage(
        header: responseHeader,
        avps: [redirectAVP], // Include the redirect AVP
      );

      // Encode and send the redirect response to the client
      final encodedResponse = responseMessage.encode();
      client.add(encodedResponse);
      print("Sent redirect response: $encodedResponse");
    } catch (e, stackTrace) {
      print("Error handling request: $e\n$stackTrace");
      _sendErrorResponse(client, "Error processing the request");
    }
  }

  /// Sends an error response back to the client if something goes wrong
  void _sendErrorResponse(Socket client, String errorMessage) {
    final errorHeader = DiameterHeader(
      version: 1,
      commandFlags: 0x00, // Response flag
      commandCode: 500, // Error response code
      applicationId: 0,
      hopByHopId: 12345,
      endToEndId: 67890,
    );

    final errorAVP = DiameterAVP.stringAVP(1, errorMessage);
    final errorMessageObj = DiameterMessage(
      header: errorHeader,
      avps: [errorAVP],
    );

    final encodedErrorMessage = errorMessageObj.encode();
    client.add(encodedErrorMessage);
    print("Sent error response: $encodedErrorMessage");
  }

  /// Handles errors during communication with the client
  void _handleError(error, Socket client) {
    print("Error: $error");
    client.close();
  }

  /// Handles client disconnection
  void _handleDone(Socket client) {
    print("Client disconnected: ${client.remoteAddress}:${client.remotePort}");
    client.close();
  }
}

void main() async {
  final agent = DiameterRedirectAgent(
    address: "127.0.0.1",  // Address where the redirect agent listens
    port: 3868,  // Local port the redirect agent listens to
    redirectAddress: "127.0.0.1",  // New server address to redirect to
    redirectPort: 3869,  // New server port to redirect to
  );

  await agent.start();
}
