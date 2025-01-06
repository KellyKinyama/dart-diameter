import 'dart:convert';
import 'dart:typed_data';

import 'diameter_avp.dart';
import 'diameter_clent.dart';
import 'diameter_message.dart';

void main() {
  final avp = DiameterAVP(
    code: 1, // IMSI AVP Code
    flags: 0,
    value: Uint8List.fromList(utf8.encode('001010000000001')),
  );

  final message = DiameterMessage(
    version: 1,
    commandFlags: 0x80, // Request
    commandCode: 316, // Update Location Request (ULR)
    applicationId: 0,
    hopByHopId: 12345,
    endToEndId: 67890,
    avps: [avp],
  );

  final encoded = message.encode();
  print('Encoded Diameter Message: $encoded');

  try {
    final message = DiameterMessage.decode(encoded);
    print('Decoded Diameter Message: Command Code: ${message.commandCode}');
  } catch (e) {
    print('Error decoding message: $e');
  }
}


// void main() {
//   final client = DiameterClient('127.0.0.1', 3868);

//   client.sendRequest(DiameterMessage(
//     version: 1,
//     commandFlags: 0x80,
//     commandCode: DiameterCommandCode.CAPABILITIES_EXCHANGE,
//     applicationId: 0,
//     hopByHopId: 12345,
//     endToEndId: 67890,
//     avps: [
//       DiameterAVP(
//         code: 264, // Host-Identity
//         flags: 0,
//         value: Uint8List.fromList(utf8.encode('Client-Identity')),
//       ),
//     ],
//   ));
// }