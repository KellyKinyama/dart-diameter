import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'avp.dart';
import 'header.dart';
import 'message.dart';

class DiameterRelayProxy {
  final String localAddress;
  final int localPort;
  final String targetAddress;
  final int targetPort;

  DiameterRelayProxy({
    required this.localAddress,
    required this.localPort,
    required this.targetAddress,
    required this.targetPort,
  });

  /// Starts the Diameter Relay Proxy
  Future<void> start() async {
    final server = await ServerSocket.bind(localAddress, localPort);
    print("Diameter Relay Proxy started on $localAddress:$localPort");

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

  /// Handles incoming requests from clients
  Future<void> _handleRequest(Uint8List data, Socket client) async {
    try {
      print("Received data: $data");

      // Decode the incoming Diameter message
      final message = DiameterMessage.decode(data);
      print("Decoded DiameterMessage:");
      print("  Version: ${message.header.version}");
      print("  Command Code: ${message.header.commandCode}");
      print("  Application ID: ${message.header.applicationId}");
      print("  Hop-by-Hop ID: ${message.header.hopByHopId}");
      print("  End-to-End ID: ${message.header.endToEndId}");
      print("  AVP Count: ${message.avps.length}");

      // Optionally modify the message here (e.g., add/remove AVPs)

      // Forward the message to the real Diameter server
      final serverSocket = await Socket.connect(targetAddress, targetPort);
      print("Forwarding to Diameter server at $targetAddress:$targetPort");
      serverSocket.add(data); // Send the request to the server

      // Listen for the server response
      serverSocket.listen(
        (serverData) => _handleServerResponse(serverData, client),
        onError: (error) => _handleError(error, client),
        onDone: () => _handleDone(client),
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      print("Error handling request: $e\n$stackTrace");
      _sendErrorResponse(client, "Error decoding Diameter message");
    }
  }

  /// Handles the response from the Diameter server and relays it to the client
  void _handleServerResponse(Uint8List data, Socket client) {
    try {
      print("Received response from Diameter server: $data");

      // Optionally modify the response message here (e.g., add/remove AVPs)

      // Relay the response to the client
      client.add(data);
      print("Relayed response to client: $data");
    } catch (e, stackTrace) {
      print("Error handling server response: $e\n$stackTrace");
      _sendErrorResponse(client, "Error relaying server response");
    }
  }

  /// Sends an error response back to the client
  void _sendErrorResponse(Socket client, String errorMessage) {
    final errorHeader = DiameterHeader(
      version: 1,
      commandFlags: 0x00, // Response flag
      commandCode: 500, // Typically error-related command code
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

  /// Handles errors during client communication
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
  final proxy = DiameterRelayProxy(
    localAddress: "127.0.0.1", // Address where the proxy listens
    localPort: 3868, // Local port to listen on
    targetAddress: "127.0.0.1", // Address of the target Diameter server
    targetPort: 3868, // Port of the target Diameter server
  );
  await proxy.start();
}
