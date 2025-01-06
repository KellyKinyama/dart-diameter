import 'dart:convert';
import 'dart:typed_data';

import '../diameter_avp.dart';
import '../diameter_message.dart';
import 'command_code.dart';
import 'handler.dart';

class DeviceWatchdogHandler implements DiameterCommandHandler {
  @override
  DiameterMessage handleRequest(DiameterMessage request) {
    print('Handling Device-Watchdog Request');
    return DiameterMessage(
      version: 1,
      commandFlags: 0x00, // Answer
      commandCode: DiameterCommandCode.DEVICE_WATCHDOG,
      applicationId: request.applicationId,
      hopByHopId: request.hopByHopId,
      endToEndId: request.endToEndId,
      avps: [
        DiameterAVP(
          code: 280, // Result-Code
          flags: 0,
          value: Uint8List.fromList(utf8.encode('2001')), // Success
        ),
      ],
    );
  }
}
