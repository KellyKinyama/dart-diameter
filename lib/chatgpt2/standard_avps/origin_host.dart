import 'dart:typed_data';

import '../diameter_message11.dart';

class OriginHostAVP extends AVP {
  OriginHostAVP(String value)
      : super(AVPCode.originHost, 0, 8 + value.length, value);

  @override
  Uint8List encode() {
    final valueBytes = utf8.encode(value);
    return Uint8List.fromList(super.encode() + valueBytes);
  }

  static OriginHostAVP decode(Uint8List data) {
    final value = utf8.decode(data);
    return OriginHostAVP(value);
  }
}
