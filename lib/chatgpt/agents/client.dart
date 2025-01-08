import 'dart:io';
import 'dart:typed_data';

import '../message.dart';

class DiameterClientAgent {
  final String serverAddress;
  final int serverPort;

  DiameterClientAgent({required this.serverAddress, required this.serverPort});

  Future<void> sendDiameterMessage(DiameterMessage message) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print("Connected to Diameter server at $serverAddress:$serverPort");

      final encodedMessage = message.encode();
      print("Sending Diameter message: $encodedMessage");

      socket.add(encodedMessage);

      socket.listen(
        (data) => _handleResponse(data),
        onError: (error) => _handleError(error),
        onDone: () {
          print("Server disconnected.");
          socket.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Error connecting to server: $e");
    }
  }

  void _handleResponse(Uint8List data) {
    final response = DiameterMessage.decode(data);
    print("Received response: $data");
    print("Decoded DiameterMessage:");
    print("  Version: ${response.header.version}");
    print("  Command Code: ${response.header.commandCode}");
    print("  Application ID: ${response.header.applicationId}");
    print("  AVP Count: ${response.avps.length}");
  }

  void _handleError(error) {
    print("Error during communication: $error");
  }
}
