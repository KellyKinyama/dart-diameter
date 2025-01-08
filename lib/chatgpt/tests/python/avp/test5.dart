import 'dart:typed_data';

class AvpFloat32 {
  final int code;
  double _value = 0.0; // Use 'double' instead of 'float'

  AvpFloat32(this.code);

  // Getter for the value
  double get value => _value;

  // Setter for the value
  set value(double v) {
    _value = v;
  }

  // Compute payload (32-bit floating point)
  Uint8List get payload {
    final buffer = ByteData(4);
    buffer.setFloat32(0, _value, Endian.big);
    return buffer.buffer.asUint8List();
  }
}

class AvpFloat64 {
  final int code;
  final int vendorId;
  double _value = 0.0; // Use 'double' instead of 'float'

  AvpFloat64(this.code, {required this.vendorId});

  // Getter for the value
  double get value => _value;

  // Setter for the value
  set value(double v) {
    _value = v;
  }

  // Compute payload (64-bit floating point)
  Uint8List get payload {
    final buffer = ByteData(8);
    buffer.setFloat64(0, _value, Endian.big);

    final vendorIdBytes = ByteData(4);
    vendorIdBytes.setUint32(0, vendorId, Endian.big);

    return Uint8List.fromList(
        vendorIdBytes.buffer.asUint8List() + buffer.buffer.asUint8List());
  }
}

void testCreateFloatType() {
  // Test Float32
  final a1 = AvpFloat32(1); // Code for BANDWIDTH
  a1.value = 128.65;
  assert(
      (a1.value - 128.65).abs() < 0.00001); // Handle floating-point precision
  assert(a1.payload.toList().toString() == [0x43, 0x00, 0xa6, 0x66].toString());

  // Test Float64 with vendor ID
  final a2 = AvpFloat64(2, vendorId: 12345); // Code for ERICSSON_COST
  a2.value = 128.65;
  assert(
      (a2.value - 128.65).abs() < 0.00001); // Handle floating-point precision
  assert(a2.payload.toList().toString() ==
      [
        0x00, 0x00, 0x30, 0x39, // Vendor ID (example)
        0x40, 0x60, 0x14, 0xcc, 0xcc, 0xcc, 0xcc, 0xcd
      ].toString());

  print('All tests passed!');
}

void main() {
  testCreateFloatType();
}
