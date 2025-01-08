import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'avp.dart';
import 'header.dart';
import 'message.dart';

class DiameterClient {
  final String serverAddress;
  final int serverPort;

  DiameterClient({required this.serverAddress, required this.serverPort});

  /// Connects to the Diameter server and sends a message
  Future<void> sendDiameterMessage(DiameterMessage message) async {
    try {
      // Establish a connection to the server
      final socket = await Socket.connect(serverAddress, serverPort);
      print("Connected to Diameter server at $serverAddress:$serverPort");

      // Encode the Diameter message
      final encodedMessage = message.encode();
      print("Sending Diameter message: $encodedMessage");

      // Send the encoded message to the server
      socket.add(encodedMessage);

      // Listen for the server response
      socket.listen(
        (data) => _handleResponse(data),
        onError: (error) => _handleError(error),
        onDone: () {
          print("Server disconnected.");
          socket.close();
        },
        cancelOnError: true, // Automatically cancel on error
      );
    } catch (e) {
      print("Error connecting to server: $e");
    }
  }

  /// Handles the server's response
  void _handleResponse(Uint8List data) {
    try {
      print("Received response: $data");

      // Decode the response message
      final response = DiameterMessage.decode(data);
      print("Decoded DiameterMessage:");
      print("  Version: ${response.header.version}");
      print("  Command Code: ${response.header.commandCode}");
      print("  Application ID: ${response.header.applicationId}");
      print("  Hop-by-Hop ID: ${response.header.hopByHopId}");
      print("  End-to-End ID: ${response.header.endToEndId}");
      print("  AVP Count: ${response.avps.length}");

      // Process AVPs in the response
      for (var avp in response.avps) {
        print("  AVP Code: ${avp.code}");
        print("  Flags: ${avp.flags}");
        print("  Value Length: ${avp.value.length}");
        if (avp.code == 1) {
          print("  Value (String): ${utf8.decode(avp.value)}");
        }
      }
    } catch (e, stackTrace) {
      print("Error decoding response: $e");
      print("Error decoding response stacktrace: $stackTrace");
    }
  }

  /// Handles errors during communication
  void _handleError(error) {
    print("Error during communication: $error");
  }
}

void main() async {
  // Create a client
  final client = DiameterClient(serverAddress: "127.0.0.1", serverPort: 3868);

  // Create a Diameter message
  final header = DiameterHeader(
    version: 1,
    commandFlags: 0x80, // Request flag
    commandCode: 257, // Capability-Exchange-Request
    applicationId: 0, // Default application
    hopByHopId: 12345,
    endToEndId: 67890,
  );

  final avp = DiameterAVP.stringAVP(1, "Client Request AVP");
  final message = DiameterMessage(header: header, avps: [avp]);

  // Send the Diameter message
  await client.sendDiameterMessage(message);
}
