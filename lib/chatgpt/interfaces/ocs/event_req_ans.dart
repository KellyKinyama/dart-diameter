import 'dart:typed_data';

import '../../avp.dart';
import '../../header.dart';
import '../../message.dart';

class EventRequest {
  DiameterHeader header;
  List<DiameterAVP> avps;

  EventRequest({required this.header, required this.avps});

  // Encode the EAR message
  Uint8List encode() {
    final message = DiameterMessage(header: header, avps: avps);
    return message.encode();
  }
}

class EventAnswer {
  DiameterHeader header;
  List<DiameterAVP> avps;

  EventAnswer({required this.header, required this.avps});

  // Encode the EAA message
  Uint8List encode() {
    final message = DiameterMessage(header: header, avps: avps);
    return message.encode();
  }
}
