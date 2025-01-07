import 'dart:typed_data';

import 'avp.dart';
import 'packunpack.dart';
import 'utils.dart';

class AVP_Integer64 extends AVP {
  AVP_Integer64(AVP a) : super(a) {
    if (a.queryPayloadSize() != 8) {
      throw InvalidAVPLengthException(a);
    }
  }

  AVP_Integer64.intValue(int code, int value)
      : super.intValue(code, _longToByte(value));

  AVP_Integer64.vendorValue(int code, int vendorId, int value)
      : super.withVendor(code, vendorId, Uint8List.fromList(_longToByte(value)));

  int queryValue() {
    return PackUnpack.unpack64(payload, 0);
  }

  void setValue(int value) {
    PackUnpack.pack64(payload, 0, value);
  }

  static List<int> _longToByte(int value) {
    var v = List<int>.filled(8, 0);
    PackUnpack.pack64(v, 0, value);
    return v;
  }
}
