import 'dart:typed_data';

import 'avp.dart';
import 'utils.dart';

class AVP_Float32 extends AVP {
  AVP_Float32(AVP a) : super(a) {
    if (a.queryPayloadSize() != 4) {
      throw InvalidAVPLengthException(a);
    }
  }

  AVP_Float32.intValue(int code, double value)
      : super.intValue(code, _floatToByte(value));

  AVP_Float32.vendorValue(int code, int vendorId, double value)
      : super.withVendor(
            code, vendorId, Uint8List.fromList(_floatToByte(value)));

  void setValue(double value) {
    setPayload(Uint8List.fromList(_floatToByte(value)));
  }

  double queryValue() {
    List<int> v = queryPayload();
    ByteData bb = ByteData.sublistView(Uint8List.fromList(v));
    return bb.getFloat32(0, Endian.big);
  }

  static List<int> _floatToByte(double value) {
    ByteData bb = ByteData(4);
    bb.setFloat32(0, value.toFloat(), Endian.big);
    return bb.buffer.asUint8List();
  }
}
