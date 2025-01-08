import 'dart:typed_data';

import 'avp.dart';

// ignore: camel_case_types
class AVP_OctetString extends AVP {
  // Constructor that copies from another AVP
  AVP_OctetString(AVP avp) : super.copy(avp);

  // Constructor for an integer value with the AVP code and value
  AVP_OctetString.intValue(int code, List<int> value)
      : super.withPayload(code, Uint8List.fromList(value));

  // Constructor for a vendor-specific AVP with the code, vendor ID, and value
  AVP_OctetString.vendorValue(int code, int vendorId, List<int> value)
      : super.withVendor(code, vendorId, Uint8List.fromList(value));

  // Query the payload value
  List<int> queryValue() {
    return queryPayload();
  }

  // Set the payload value
  void setValue(List<int> value) {
    setPayload(Uint8List.fromList(value));
  }
}
