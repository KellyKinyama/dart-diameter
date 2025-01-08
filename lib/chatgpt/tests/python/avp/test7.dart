import 'dart:typed_data';
import 'dart:convert';

class AvpUtf8String {
  final int code;
  String _value = "";
  Uint8List _payload = Uint8List(0);

  AvpUtf8String(this.code);

  // Getter for the value
  String get value => _value;

  // Setter for the value
  set value(String v) {
    _value = v;
    _payload = utf8.encode(_value);
  }

  // Compute payload for UTF-8 string
  Uint8List get payload => _payload;
}

void testCreateUtf8Type() {
  // Test UTF8 String AVP with Subscription ID Data
  final a1 = AvpUtf8String(1); // AVP code for SUBSCRIPTION_ID_DATA
  a1.value = "485079164547";
  assert(a1.value == "485079164547");
  assert(
      a1.payload.toList().toString() == utf8.encode("485079164547").toString());

  // Test UTF8 String AVP with User Name (containing Chinese characters)
  final a2 = AvpUtf8String(2); // AVP code for USER_NAME
  a2.value = "汉语"; // Chinese characters for 'Chinese language'
  assert(a2.value == "汉语");
  assert(a2.payload.toList().toString() == utf8.encode("汉语").toString());

  print('All tests passed!');
}

void main() {
  testCreateUtf8Type();
}
