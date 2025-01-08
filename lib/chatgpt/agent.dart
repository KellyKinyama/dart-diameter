import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'avp.dart';
import 'header.dart';
import 'message.dart';

class DiameterAgent {
  final String address;
  final int port;
  final String remoteServerAddress;
  final int remoteServerPort;

  DiameterAgent({
    required this.address,
    required this.port,
    required this.remoteServerAddress,
    required this.remoteServerPort,
  });

  /// Starts the Diameter agent, listening for client connections
  Future<void> start() async {
    final server = await ServerSocket.bind(address, port);
    print("Diameter agent started on $address:$port");

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

  /// Handles incoming requests and forwards them to the remote server
  void _handleRequest(Uint8List data, Socket client) async {
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

      // Forward the message to the remote server
      final clientToServerSocket =
          await Socket.connect(remoteServerAddress, remoteServerPort);
      print(
          "Forwarding request to remote server at $remoteServerAddress:$remoteServerPort");

      // Encode and send the Diameter message to the remote server
      final encodedMessage = message.encode();
      clientToServerSocket.add(encodedMessage);

      // Listen for the remote server's response
      clientToServerSocket.listen(
        (responseData) =>
            _handleServerResponse(responseData, client, clientToServerSocket),
        onError: (error) => _handleError(error, client),
        onDone: () {
          print("Remote server disconnected.");
          clientToServerSocket.close();
        },
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      print("Error handling request: $e\n$stackTrace");
      _sendErrorResponse(client, "Error processing the request");
    }
  }

  /// Handles the response from the remote server and forwards it to the client
  void _handleServerResponse(
      Uint8List responseData, Socket client, Socket serverSocket) {
    try {
      print("Received response from remote server: $responseData");

      // Decode the response message
      final response = DiameterMessage.decode(responseData);
      print("Decoded DiameterMessage:");
      print("  Version: ${response.header.version}");
      print("  Command Code: ${response.header.commandCode}");
      print("  Application ID: ${response.header.applicationId}");
      print("  Hop-by-Hop ID: ${response.header.hopByHopId}");
      print("  End-to-End ID: ${response.header.endToEndId}");
      print("  AVP Count: ${response.avps.length}");

      // Forward the response to the original client
      client.add(responseData);
      print("Forwarded response back to client.");
    } catch (e) {
      print("Error decoding or forwarding the response: $e");
      _sendErrorResponse(client, "Error forwarding response");
    } finally {
      serverSocket.close();
      client.close();
    }
  }

  /// Sends an error response back to the client
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
  final agent = DiameterAgent(
    address: "127.0.0.1",
    port: 3868, // Local port the agent listens to
    remoteServerAddress: "127.0.0.1", // Address of the remote Diameter server
    remoteServerPort: 3868, // Port of the remote Diameter server
  );

  await agent.start();
}
