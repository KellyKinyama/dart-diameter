import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:dart_diameter/misc/parser.dart';

class HssServer {
  final int port;

  HssServer(this.port);

  // Mock database for subscriber profiles
  final Map<String, Map<String, String>> subscriberDatabase = {
    '001010000000001': {
      // Example IMSI
      'authKey': 'mocked-auth-key',
      'apn': 'internet',
      'qosProfile': 'default',
    }
  };

  Future<void> start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('HSS server listening on port $port...');

    server.listen((Socket client) {
      print(
          'Client connected: ${client.remoteAddress.address}:${client.remotePort}');
      client.listen((data) {
        final message = DiameterMessage.decode(Uint8List.fromList(data));
        print('Received Command Code: ${message.commandCode}');

        // Handle received DIAMETER messages
        final response = _handleMessage(message);
        client.add(response.encode());
        client.close();
      });
    });
  }

  DiameterMessage _handleMessage(DiameterMessage message) {
    switch (message.commandCode) {
      case 318: // Authentication-Information-Request (AIR)
        return _handleAIR(message);
      case 316: // Update-Location-Request (ULR)
        return _handleULR(message);
      default:
        print('Unsupported Command Code: ${message.commandCode}');
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

  DiameterMessage _handleAIR(DiameterMessage message) {
    final imsi = _extractAvpValue(message, 1); // AVP code 1: IMSI
    if (subscriberDatabase.containsKey(imsi)) {
      final authInfo = subscriberDatabase[imsi]!['authKey']!;
      final avp = DiameterAVP(
        code: 318, // Result-Code
        flags: 0,
        length: 12,
        value: Uint8List.fromList(utf8.encode(authInfo)),
      );

      return DiameterMessage(
        version: 1,
        messageLength: 20 + avp.length,
        commandFlags: 0x40, // Answer message
        commandCode: 318,
        applicationId: message.applicationId,
        hopByHopId: message.hopByHopId,
        endToEndId: message.endToEndId,
        avps: [avp],
      );
    } else {
      print('Unknown IMSI: $imsi');
      return DiameterMessage(
        version: 1,
        messageLength: 20,
        commandFlags: 0x40,
        commandCode: 318,
        applicationId: message.applicationId,
        hopByHopId: message.hopByHopId,
        endToEndId: message.endToEndId,
        avps: [],
      );
    }
  }

  DiameterMessage _handleULR(DiameterMessage message) {
    final imsi = _extractAvpValue(message, 1); // AVP code 1: IMSI
    if (subscriberDatabase.containsKey(imsi)) {
      final apn = subscriberDatabase[imsi]!['apn']!;
      final qos = subscriberDatabase[imsi]!['qosProfile']!;
      final apnAvp = DiameterAVP(
        code: 140, // Example APN code
        flags: 0,
        length: 12,
        value: Uint8List.fromList(utf8.encode(apn)),
      );
      final qosAvp = DiameterAVP(
        code: 101, // Example QoS code
        flags: 0,
        length: 12,
        value: Uint8List.fromList(utf8.encode(qos)),
      );

      return DiameterMessage(
        version: 1,
        messageLength: 20 + apnAvp.length + qosAvp.length,
        commandFlags: 0x40,
        commandCode: 316,
        applicationId: message.applicationId,
        hopByHopId: message.hopByHopId,
        endToEndId: message.endToEndId,
        avps: [apnAvp, qosAvp],
      );
    } else {
      print('Unknown IMSI: $imsi');
      return DiameterMessage(
        version: 1,
        messageLength: 20,
        commandFlags: 0x40,
        commandCode: 316,
        applicationId: message.applicationId,
        hopByHopId: message.hopByHopId,
        endToEndId: message.endToEndId,
        avps: [],
      );
    }
  }

  String _extractAvpValue(DiameterMessage message, int avpCode) {
    final avp = message.avps.firstWhere((avp) => avp.code == avpCode,
        orElse: () =>
            DiameterAVP(code: 0, flags: 0, length: 0, value: Uint8List(0)));
    return utf8.decode(avp.value);
  }
}
