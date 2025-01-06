import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'diameter_avp.dart';
import 'diameter_message.dart';

class DiameterClient {
  final String host;
  final int port;

  DiameterClient(this.host, this.port);

  void sendRequest() async {
    final socket = await Socket.connect(host, port);
    print('Connected to Diameter Server');

    final request = DiameterMessage(
      version: 1,
      commandFlags: 0x80,
      commandCode: 316,
      applicationId: 0,
      hopByHopId: 12345,
      endToEndId: 67890,
      avps: [
        DiameterAVP(
            code: 1, flags: 0, value: Uint8List.fromList(utf8.encode('Test')))
      ],
    ).encode();

    socket.add(request);
    socket.listen((data) {
      final response = DiameterMessage.decode(data);
      print('Received response with Command Code: ${response.commandCode}');
      socket.destroy();
    });
  }
}
