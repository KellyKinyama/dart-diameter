import 'dart:typed_data';

class AvpTime {
  final int code;
  DateTime _value;
  Uint8List _payload;

  AvpTime(this.code)
      : _value = DateTime(0),
        _payload = Uint8List(0);

  // Getter for the value (as DateTime)
  DateTime get value => _value;

  // Setter for the value
  set value(DateTime v) {
    _value = DateTime(v.year, v.month, v.day, v.hour, v.minute,
        v.second); // Drop microseconds
    _payload = Uint8List(4); // Simplified for this example
    _payload.buffer
        .asByteData()
        .setInt32(0, _value.millisecondsSinceEpoch ~/ 1000); // Store seconds
  }

  // Getter for the payload (seconds since epoch)
  Uint8List get payload => _payload;

  // For comparing payload to hexadecimal
  String get payloadHex =>
      _payload.map((e) => e.toRadixString(16).padLeft(2, '0')).join('');
}

void testCreateTimeType() {
  final a = AvpTime(1); // AVP code for EVENT_TIMESTAMP

  final now = DateTime.now();
  a.value = now;

  // AvpTime drops microseconds while encoding, as the spec accepts only second precision
  final nowWithoutMicro =
      DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
  assert(a.value == nowWithoutMicro);

  // The date when NTP-format timestamps would overflow
  final overflowDate = DateTime(2036, 2, 7, 6, 28, 16);
  final t = AvpTime(1);
  t.value = overflowDate;
  assert(t.value == overflowDate);

  // After 2036 (future date)
  final after2036 = DateTime(2048, 2, 7, 6, 28, 16);
  t.value = after2036;
  assert(t.value == after2036);
  assert(t.payloadHex == "16925e80");

  // Test with custom payload
  final t2 = AvpTime(1);
  t2.value = DateTime(2062, 10, 27, 11, 8, 46);
  assert(t2.value == DateTime(2062, 10, 27, 11, 8, 46));

  print('All tests passed!');
}

void main() {
  testCreateTimeType();
}
