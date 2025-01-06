import 'dart:io';
import '../base_protocol/diameter_avp.dart';
import '../base_protocol/diameter_message.dart';

class HSSServer {
  final int port;
  final Map<String, Map<String, dynamic>> subscribers = {
    'Session123': {'balance': 1000, 'profile': 'Premium'},
    'Session456': {'balance': 500, 'profile': 'Basic'},
  };

  HSSServer(this.port);

  void start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('HSS Server running on port $port');

    server.listen((Socket client) {
      client.listen((data) {
        try {
          final request = DiameterMessage.decode(data);
          print('Received Command Code: ${request.commandCode}');

          if (request.commandCode == 300) {
            final response = handleSubscriberQuery(request);
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

  DiameterMessage handleSubscriberQuery(DiameterMessage request) {
    final sessionId = String.fromCharCodes(
        request.avps.firstWhere((avp) => avp.code == 263).value);

    final subscriber = subscribers[sessionId];

    if (subscriber != null) {
      return DiameterMessage(
        version: 1,
        commandFlags: 0x00, // Answer
        commandCode: 300,
        applicationId: 4,
        hopByHopId: request.hopByHopId,
        endToEndId: request.endToEndId,
        avps: [
          DiameterAVP.stringAVP(263, sessionId),
          DiameterAVP.integerAVP(200, subscriber['balance']),
          DiameterAVP.stringAVP(300, subscriber['profile']),
        ],
      );
    } else {
      return DiameterMessage(
        version: 1,
        commandFlags: 0x00, // Answer
        commandCode: 300,
        applicationId: 4,
        hopByHopId: request.hopByHopId,
        endToEndId: request.endToEndId,
        avps: [
          DiameterAVP.stringAVP(263, sessionId),
          DiameterAVP.integerAVP(268, 5001), // Result-Code: User Not Found
        ],
      );
    }
  }
}
