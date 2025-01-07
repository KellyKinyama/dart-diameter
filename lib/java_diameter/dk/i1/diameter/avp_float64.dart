import 'dart:typed_data';

import 'avp.dart';
import 'utils.dart';

class AVP_Float64 extends AVP {
  AVP_Float64(AVP a) : super(a) {
    if (a.queryPayloadSize() != 8) {
      throw InvalidAVPLengthException(a);
    }
  }

  AVP_Float64.intValue(int code, double value)
      : super.intValue(code, _doubleToByte(value));

  AVP_Float64.vendorValue(int code, int vendorId, double value)
      : super.withVendor(
            code, vendorId, Uint8List.fromList(_doubleToByte(value)));

  void setValue(double value) {
    setPayload(Uint8List.fromList(_doubleToByte(value)));
  }

  double queryValue() {
    List<int> v = queryPayload();
    ByteData bb = ByteData.sublistView(Uint8List.fromList(v));
    return bb.getFloat64(0, Endian.big);
  }

  static List<int> _doubleToByte(double value) {
    ByteData bb = ByteData(8);
    bb.setFloat64(0, value, Endian.big);
    return bb.buffer.asUint8List();
  }
}
