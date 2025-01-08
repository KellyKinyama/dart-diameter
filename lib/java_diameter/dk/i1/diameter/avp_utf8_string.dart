import 'dart:typed_data';
import 'avp.dart';

// ignore: camel_case_types
class AVP_UTF8String extends AVP {
  AVP_UTF8String(AVP a)
      : super.copy(a); // Assuming the AVP class has a copy constructor

  AVP_UTF8String.intValue(int code, String value)
      : super.withPayload(code, Uint8List.fromList(_stringToBytes(value)));

  AVP_UTF8String.vendorValue(int code, int vendorId, String value)
      : super.withVendor(
            code, vendorId, Uint8List.fromList(_stringToBytes(value)));

  String queryValue() {
    try {
      return String.fromCharCodes(queryPayload());
    } catch (e) {
      throw e.toString();
    }
  }

  void setValue(String value) {
    setPayload(Uint8List.fromList(_stringToBytes(value)));
  }

  static List<int> _stringToBytes(String value) {
    return value.codeUnits;
  }
}
