import 'dart:io';
import 'dart:typed_data';

import '../base_protocol/commands/command_code.dart';
import '../base_protocol/diameter_avp.dart';
import '../base_protocol/diameter_message.dart';

class OnlineChargingServer {
  final int port;
  final String hssHost;
  final int hssPort;

  OnlineChargingServer(this.port, this.hssHost, this.hssPort);

  void start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Online Charging Server running on port $port');

    server.listen((Socket client) {
      client.listen((data) async {
        try {
          final request = DiameterMessage.decode(data);
          print('Received Command Code: ${request.commandCode}');

          if (request.commandCode == DiameterCommandCode.CREDIT_CONTROL) {
            final response = await handleCreditControlRequest(request);
            client.add(response.encode());
          } else {
            print('Unsupported Command Code: ${request.commandCode}');
          }
        } catch (e) {
          print('Failed to decode message: $e');
        }
      });
    });
  }

  Future<DiameterMessage> handleCreditControlRequest(
      DiameterMessage request) async {
    print('Handling Credit-Control Request');

    final sessionId = String.fromCharCodes(
        request.avps.firstWhere((avp) => avp.code == 263).value);

    final hssResponse = await queryHSS(sessionId);

    if (hssResponse == null || hssResponse['balance'] == null) {
      return DiameterMessage(
        version: 1,
        commandFlags: 0x00, // Answer
        commandCode: DiameterCommandCode.CREDIT_CONTROL,
        applicationId: request.applicationId,
        hopByHopId: request.hopByHopId,
        endToEndId: request.endToEndId,
        avps: [
          DiameterAVP.stringAVP(263, sessionId),
          DiameterAVP.integerAVP(268, 5001), // Result-Code: User Not Found
        ],
      );
    }

    final balance = hssResponse['balance'];
    final requestedUnits = ByteData.sublistView(
            request.avps.firstWhere((avp) => avp.code == 100).value)
        .getUint32(0, Endian.big);
    final grantedUnits = (balance >= requestedUnits) ? requestedUnits : balance;

    if (grantedUnits > 0) {
      updateHSSBalance(sessionId, balance - grantedUnits);
    }

    return DiameterMessage(
      version: 1,
      commandFlags: 0x00, // Answer
      commandCode: DiameterCommandCode.CREDIT_CONTROL,
      applicationId: request.applicationId,
      hopByHopId: request.hopByHopId,
      endToEndId: request.endToEndId,
      avps: [
        DiameterAVP.stringAVP(263, sessionId),
        DiameterAVP.integerAVP(268, 2001), // Result-Code: Success
        DiameterAVP.integerAVP(100, grantedUnits), // Granted-Units
      ],
    );
  }

  Future<Map<String, dynamic>?> queryHSS(String sessionId) async {
    try {
      final client = await Socket.connect(hssHost, hssPort);
      final request = DiameterMessage(
        version: 1,
        commandFlags: 0x80, // Request
        commandCode: 300, // HSS Query Command
        applicationId: 4,
        hopByHopId: 12345,
        endToEndId: 67890,
        avps: [
          DiameterAVP.stringAVP(263, sessionId), // Session-Id
        ],
      );

      client.add(request.encode());

      final data = await client.first;
      client.close();

      final response = DiameterMessage.decode(data);
      final balance = ByteData.sublistView(
              response.avps.firstWhere((avp) => avp.code == 200).value)
          .getUint32(0, Endian.big);
      final profile = String.fromCharCodes(
          response.avps.firstWhere((avp) => avp.code == 300).value);

      return {'balance': balance, 'profile': profile};
    } catch (e) {
      print('HSS Query Failed: $e');
      return null;
    }
  }

  void updateHSSBalance(String sessionId, int newBalance) {
    // Simulate updating HSS balance. In real deployment, this would send a Diameter request to update the HSS.
    print('Updating HSS Balance for $sessionId to $newBalance');
  }
}
