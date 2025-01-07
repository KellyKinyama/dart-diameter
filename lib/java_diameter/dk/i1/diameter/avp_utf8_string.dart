import 'dart:typed_data';

import 'avp.dart';

class AVP_UTF8String extends AVP {
  AVP_UTF8String(AVP a) : super(a);

  AVP_UTF8String.intValue(int code, String value)
      : super.intValue(code, _stringToBytes(value));

  AVP_UTF8String.vendorValue(int code, int vendorId, String value)
      : super.withVendor(
            code, vendorId, Uint8List.fromList(_stringToBytes(value)));

  String queryValue() {
    try {
      return String.fromCharCodes(queryPayload());
    } catch (e) {
      return null;
    }
  }

  void setValue(String value) {
    setPayload(Uint8List.fromList(_stringToBytes(value)));
  }

  static List<int> _stringToBytes(String value) {
    return value.codeUnits;
  }
}
