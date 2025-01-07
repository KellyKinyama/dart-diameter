import 'avp.dart';

class AVP_OctetString extends AVP {
  AVP_OctetString(AVP avp) : super(avp);

  AVP_OctetString.intValue(int code, List<int> value) : super.intValue(code, value);

  AVP_OctetString.vendorValue(int code, int vendorId, List<int> value)
      : super.withVendor(code, vendorId, value);

  List<int> queryValue() {
    return queryPayload();
  }

  void setValue(List<int> value) {
    setPayload(value, 0, value.length);
  }
}
