import 'dart:convert';
import 'dart:typed_data';

import '../diameter_avp.dart';
import '../diameter_message.dart';
import 'command_code.dart';
import 'handler.dart';

class CapabilitiesExchangeHandler implements DiameterCommandHandler {
  @override
  DiameterMessage handleRequest(DiameterMessage request) {
    print('Handling Capabilities-Exchange Request');
    return DiameterMessage(
      version: 1,
      commandFlags: 0x00, // Answer
      commandCode: DiameterCommandCode.CAPABILITIES_EXCHANGE,
      applicationId: request.applicationId,
      hopByHopId: request.hopByHopId,
      endToEndId: request.endToEndId,
      avps: [
        DiameterAVP(
          code: 264, // Host-Identity
          flags: 0,
          value: Uint8List.fromList(utf8.encode('Diameter-Server')),
        ),
        DiameterAVP(
          code: 296, // Vendor-Id
          flags: 0,
          value: Uint8List.fromList(utf8.encode('10415')), // Example vendor
        ),
      ],
    );
  }
}
