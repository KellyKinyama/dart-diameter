import 'dart:typed_data';

import '../../avp.dart';
import '../../header.dart';
import '../../message.dart';

class CreditControlRequest {
  DiameterHeader header;
  List<DiameterAVP> avps;

  CreditControlRequest({required this.header, required this.avps});

  // Encode the CCR message
  Uint8List encode() {
    final message = DiameterMessage(header: header, avps: avps);
    return message.encode();
  }
}
