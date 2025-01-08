import 'dart:typed_data';

class AvpOctetString {
  final int code;
  Uint8List _value = Uint8List(0);
  Uint8List _payload = Uint8List(0);

  AvpOctetString(this.code);

  // Getter for the value (as Uint8List)
  Uint8List get value => _value;

  // Setter for the value
  set value(Uint8List v) {
    _value = v;
    _payload = _value; // Octet string: value equals payload
  }

  // Getter for the payload (just the value in case of octet string)
  Uint8List get payload => _payload;
}

void testCreateOctetStringType() {
  // Test Octet String AVP for User Password
  final a = AvpOctetString(1); // AVP code for USER_PASSWORD

  // For octet strings, the value should always equal the payload, even when not set
  assert(a.value.isEmpty); // Default is an empty Uint8List
  assert(a.payload.isEmpty); // Default is an empty Uint8List

  // Set the value and check that it matches the payload
  a.value = Uint8List.fromList(
      [0x73, 0x65, 0x63, 0x72, 0x65, 0x74]); // "secret" in byte form
  assert(a.value == a.payload);
  assert(a.payload.toList().toString() ==
      [0x73, 0x65, 0x63, 0x72, 0x65, 0x74].toString());

  print('All tests passed!');
}

void main() {
  testCreateOctetStringType();
}
