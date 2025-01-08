import 'dart:typed_data';

import 'avp.dart';

class InvalidAVPLengthException implements Exception {
  final AVP avp;
  InvalidAVPLengthException(this.avp);
}

// ignore: camel_case_types
class AVP_Unsigned32 extends AVP {
  AVP_Unsigned32(AVP a) : super(Uint8List(4)) {
    if (a.queryPayloadSize() != 4) {
      throw InvalidAVPLengthException(a);
    }
  }

  AVP_Unsigned32.intValue(int code, int value) : super( Uint8List.fromList(_intToByte(value)));

  AVP_Unsigned32.vendorValue(int code, int vendorId, int value)
      : super.withVendor(code, vendorId, Uint8List.fromList(_intToByte(value)));

  int queryValue() {
    return _unpack32(payload, 0);
  }

  void setValue(int value) {
    _pack32(payload, 0, value);
  }

  static List<int> _intToByte(int value) {
    return _pack32(new List<int>.filled(4, 0), 0, value);
  }

  static int _unpack32(List<int> data, int offset) {
    return ByteData.sublistView(Uint8List.fromList(data))
            .getInt32(offset, Endian.big) &
        0xFFFFFFFF;
  }

  static List<int> _pack32(List<int> data, int offset, int value) {
    ByteData.sublistView(Uint8List.fromList(data))
        .setInt32(offset, value, Endian.big);
    return data;
  }

  // Constructor to initialize with a vendor ID
  AVP_Unsigned32.withVendor(int code, int vendorId, int value)
      : super.withVendor(code, vendorId, Uint8List.fromList([value]));

  // Constructor to initialize with an integer value
  //AVP_Unsigned32.intValue(int code, int value) : super.withPayload(code, [value]);
}
