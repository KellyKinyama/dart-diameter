import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_diameter/misc/parser.dart';

class HssClient {
  final String serverAddress;
  final int serverPort;

  HssClient(this.serverAddress, this.serverPort);

  Future<void> sendAir(String imsi) async {
    print('Connecting to HSS at $serverAddress:$serverPort...');
    final socket = await Socket.connect(serverAddress, serverPort);

    final avp = DiameterAVP(
      code: 1, // IMSI AVP code
      flags: 0,
      length: 12,
      value: Uint8List.fromList(utf8.encode(imsi)),
    );

    final airMessage = DiameterMessage(
      version: 1,
      messageLength: 20 + avp.length,
      commandFlags: 0x80,
      commandCode: 318,
      applicationId: 0,
      hopByHopId: 12345,
      endToEndId: 67890,
      avps: [avp],
    );

    socket.add(airMessage.encode());
    print('AIR sent to HSS.');

    socket.listen((data) {
      final response = DiameterMessage.decode(Uint8List.fromList(data));
      print('Received AIR response with Command Code: ${response.commandCode}');
      socket.close();
    });
  }
}
