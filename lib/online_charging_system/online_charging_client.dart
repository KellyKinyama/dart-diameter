import 'dart:io';
import 'dart:typed_data';

import '../base_protocol/commands/command_code.dart';
import '../base_protocol/diameter_avp.dart';
import '../base_protocol/diameter_message.dart';

class OnlineChargingClient {
  final String host;
  final int port;
  late Socket clientSocket;

  OnlineChargingClient(this.host, this.port);

  Future<void> connect() async {
    clientSocket = await Socket.connect(host, port);
    print('Connected to Online Charging Server');
  }

  Future<void> requestCredit(String sessionId, int requestedUnits) async {
    final request = DiameterMessage(
      version: 1,
      commandFlags: 0x80, // Request
      commandCode: DiameterCommandCode.CREDIT_CONTROL,
      applicationId: 4, // Credit-Control Application
      hopByHopId: 12345,
      endToEndId: 67890,
      avps: [
        DiameterAVP.stringAVP(263, sessionId), // Session-Id
        DiameterAVP.integerAVP(100, requestedUnits), // Requested-Units
      ],
    );

    clientSocket.add(request.encode());

    clientSocket.listen((data) {
      final response = DiameterMessage.decode(data);
      print(
          'Received Response: Granted Units - ${ByteData.sublistView(response.avps.firstWhere((avp) => avp.code == 100).value).getUint32(0, Endian.big)}');
    });
  }

  void close() {
    clientSocket.close();
    print('Disconnected from Online Charging Server');
  }
}
