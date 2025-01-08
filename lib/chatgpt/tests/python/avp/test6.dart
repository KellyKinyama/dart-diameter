import 'dart:typed_data';

class AvpInteger32 {
  final int code;
  int _value = 0;
  Uint8List _payload = Uint8List(0);

  AvpInteger32(this.code, {Uint8List? payload}) {
    if (payload != null) {
      _payload = payload;
      _value = ByteData.sublistView(_payload).getInt32(0, Endian.big);
    }
  }

  // Getter for the value
  int get value => _value;

  // Setter for the value
  set value(int v) {
    _value = v;
    final buffer = ByteData(4);
    buffer.setInt32(0, _value, Endian.big);
    _payload = buffer.buffer.asUint8List();
  }

  // Compute payload for Integer32 (4-byte signed integer)
  Uint8List get payload => _payload;
}

class AvpInteger64 {
  final int code;
  int _value = 0;
  Uint8List _payload = Uint8List(0);

  AvpInteger64(this.code);

  // Getter for the value
  int get value => _value;

  // Setter for the value
  set value(int v) {
    _value = v;
    final buffer = ByteData(8);
    buffer.setInt64(0, _value, Endian.big);
    _payload = buffer.buffer.asUint8List();
  }

  // Compute payload for Integer64 (8-byte signed integer)
  Uint8List get payload => _payload;
}

void testCreateSignedIntType() {
  // Test Integer32 (Enumerated) AVP
  final a1 = AvpInteger32(1); // AVP code for ACCT_INPUT_PACKETS
  a1.value = 294967;
  assert(a1.value == 294967);
  assert(a1.payload.toList().toString() == [0x00, 0x04, 0x80, 0x37].toString());

  final a2 = AvpInteger32(2); // AVP code for TGPP_CAUSE_CODE
  a2.value = -1;
  assert(a2.value == -1);
  assert(a2.payload.toList().toString() == [0xff, 0xff, 0xff, 0xff].toString());

  // Create by passing the payload in constructor
  final a3 =
      AvpInteger32(2, payload: Uint8List.fromList([0xff, 0xff, 0xff, 0xff]));
  assert(a3.value == -1);

  // Test Integer64 AVP
  final a4 = AvpInteger64(3); // AVP code for VALUE_DIGITS
  a4.value = 9223372036854775800;
  assert(a4.value == 9223372036854775800);
  assert(a4.payload.toList().toString() ==
      [0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xf8].toString());

  print('All tests passed!');
}

void main() {
  testCreateSignedIntType();
}
