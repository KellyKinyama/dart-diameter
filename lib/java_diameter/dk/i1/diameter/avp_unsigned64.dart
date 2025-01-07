import 'dart:typed_data';

import 'avp.dart';

class InvalidAVPLengthException implements Exception {
  final AVP avp;
  InvalidAVPLengthException(this.avp);
}



class AVP_Unsigned64 extends AVP {
  AVP_Unsigned64(AVP a) : super(a) {
    if (a.queryPayloadSize() != 8) {
      throw InvalidAVPLengthException(a);
    }
  }

  AVP_Unsigned64.intValue(int code, int value)
      : super.intValue(code, _longToByte(value));

  AVP_Unsigned64.vendorValue(int code, int vendorId, int value)
      : super.withVendor(code, vendorId, _longToByte(value));

  int queryValue() {
    return _unpack64(payload, 0);
  }

  void setValue(int value) {
    _pack64(payload, 0, value);
  }

  static List<int> _longToByte(int value) {
    return _pack64(new List<int>.filled(8, 0), 0, value);
  }

  static int _unpack64(List<int> data, int offset) {
    return ByteData.sublistView(Uint8List.fromList(data))
            .getInt64(offset, Endian.big) &
        0xFFFFFFFFFFFFFFFF;
  }

  static List<int> _pack64(List<int> data, int offset, int value) {
    ByteData.sublistView(Uint8List.fromList(data))
        .setInt64(offset, value, Endian.big);
    return data;
  }
}
