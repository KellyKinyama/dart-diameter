import 'dart:typed_data';

import 'avp.dart';
import 'avp_unsinged32.dart';
import 'packunpack.dart';
import 'utils.dart';

// ignore: camel_case_types
class AVP_Integer32 extends AVP {
  AVP_Integer32(AVP a) : super(Uint8List(4)) {
    if (a.queryPayloadSize() != 4) {
      throw InvalidAVPLengthException(a);
    }
    setPayload(a.queryPayload());
  }

  AVP_Integer32.intValue(int code, int value)
      : super.withPayload(code, Uint8List.fromList(_intToByte(value)));

  AVP_Integer32.vendorValue(int code, int vendorId, int value)
      : super.withVendor(code, vendorId, Uint8List.fromList(_intToByte(value)));

  int queryValue() {
    return PackUnpack.unpack32(payload, 0);
  }

  void setValue(int value) {
    PackUnpack.pack32(payload, 0, value);
  }

  static List<int> _intToByte(int value) {
    var v = List<int>.filled(4, 0);
    PackUnpack.pack32(v, 0, value);
    return v;
  }
}
