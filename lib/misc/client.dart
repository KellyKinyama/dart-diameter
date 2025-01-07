import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:dart_diameter/misc/parser.dart';

class DiameterClient {
  final String serverAddress;
  final int serverPort;

  DiameterClient(this.serverAddress, this.serverPort);

  Future<void> sendCer() async {
    print('Connecting to DIAMETER server at $serverAddress:$serverPort...');
    final socket = await Socket.connect(serverAddress, serverPort);

    // Create a Capabilities-Exchange-Request (CER) message
    final avp = DiameterAVP(
      code: 1, // Example AVP (Origin-Host)
      flags: 0,
      length: 12,
      value: Uint8List.fromList(utf8.encode('client.example.com')),
    );

    final cerMessage = DiameterMessage(
      version: 1,
      messageLength: 20 + avp.length,
      commandFlags: 0x80, // Request message
      commandCode: 272, // CER
      applicationId: 0,
      hopByHopId: 12345,
      endToEndId: 67890,
      avps: [avp],
    );

    // Send the message
    socket.add(cerMessage.encode());
    print('CER sent to server.');

    // Wait for the response
    socket.listen((data) {
      final response = DiameterMessage.decode(Uint8List.fromList(data));
      print('Received response with Command Code: ${response.commandCode}');
      socket.close();
    });
  }
}
