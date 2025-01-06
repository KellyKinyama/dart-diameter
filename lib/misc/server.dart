import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:dart_diameter/misc/parser.dart';

class DiameterServer {
  final int port;

  DiameterServer(this.port);

  Future<void> start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('DIAMETER server listening on port $port...');

    server.listen((Socket client) {
      print(
          'Client connected: ${client.remoteAddress.address}:${client.remotePort}');

      client.listen((data) {
        // Decode the received DIAMETER message
        final message = DiameterMessage.decode(Uint8List.fromList(data));
        print('Received message with Command Code: ${message.commandCode}');

        // Respond to the client
        final response = _handleMessage(message);
        client.add(response.encode());
        client.close();
      });
    });
  }

  DiameterMessage _handleMessage(DiameterMessage message) {
    if (message.commandCode == 272) {
      // Capabilities-Exchange-Request (CER)
      print('Handling Capabilities-Exchange-Request (CER)');

      // Create a Capabilities-Exchange-Answer (CEA)
      final avp = DiameterAVP(
        code: 268, // Result-Code
        flags: 0,
        length: 12,
        value: Uint8List.fromList(utf8.encode('2001')), // Success
      );

      return DiameterMessage(
        version: 1,
        messageLength: 20 + avp.length,
        commandFlags: 0x40, // Answer message
        commandCode: 272,
        applicationId: message.applicationId,
        hopByHopId: message.hopByHopId,
        endToEndId: message.endToEndId,
        avps: [avp],
      );
    }

    // Handle other commands (not implemented here)
    return DiameterMessage(
      version: 1,
      messageLength: 20,
      commandFlags: 0x40,
      commandCode: message.commandCode,
      applicationId: message.applicationId,
      hopByHopId: message.hopByHopId,
      endToEndId: message.endToEndId,
      avps: [],
    );
  }
}
