import 'dart:typed_data';

import '../../avp.dart';
import '../../header.dart';
import '../../message.dart';

class CreditControlAnswer {
  DiameterHeader header;
  List<DiameterAVP> avps;

  CreditControlAnswer({required this.header, required this.avps});

  // Encode the CCA message
  Uint8List encode() {
    final message = DiameterMessage(header: header, avps: avps);
    return message.encode();
  }
}
