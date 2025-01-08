import 'dart:io';

import '../avp.dart';
import '../header.dart';
import '../message.dart';

class DiameterServerAgent {
  final int serverPort;

  DiameterServerAgent({required this.serverPort});

  Future<void> startServer() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, serverPort);
    print("Diameter server listening on port $serverPort");

    await for (var socket in server) {
      print("Client connected: ${socket.remoteAddress}");
      _handleRequest(socket);
    }
  }

  void _handleRequest(Socket socket) async {
    try {
      final data = await socket.first;
      print("Received message: $data");

      final request = DiameterMessage.decode(data);
      print("Decoded request: $request");

      final response = _createResponse(request);
      socket.add(response.encode());
      socket.close();
    } catch (e) {
      print("Error processing request: $e");
      socket.close();
    }
  }

  DiameterMessage _createResponse(DiameterMessage request) {
    // Example: create a response with the same header but different command code
    final header = DiameterHeader(
      version: request.header.version,
      commandFlags: 0x80, // Response flag
      commandCode: 258, // Some command code
      applicationId: request.header.applicationId,
      hopByHopId: request.header.hopByHopId,
      endToEndId: request.header.endToEndId,
    );

    final avp = DiameterAVP.stringAVP(1, "Response from server");
    return DiameterMessage(header: header, avps: [avp]);
  }
}
