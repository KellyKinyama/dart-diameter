import 'dart:typed_data';

import '../avp.dart';

class AvpFloat64 extends DiameterAVP {
  AvpFloat64({
    required int code,
    required int flags,
    required int length,
    required int vendorId,
    required double value,
    String name = 'AvpFloat64',
  }) : super(
          code: code,
          flags: flags,
          length: length,
          vendorId: vendorId,
          value: AvpFloat64._encodeFloat64(value),
          name: name,
        );

  // Getter for `value`
  //@override
  double get floatValue {
    try {
      return AvpFloat64._decodeFloat64(super.value);
    } catch (e) {
      throw Exception(
        "${super.name} value ${super.value} is not a valid 64-bit float: $e",
      );
    }
  }

  // Setter for `value`
  //@override
  set floatValue(double newValue) {
    try {
      super.value = AvpFloat64._encodeFloat64(newValue);
      length = super.value.length + 8; // Update length accordingly
    } catch (e) {
      throw Exception(
        "${super.name} value $newValue is not a valid 64-bit float: $e",
      );
    }
  }

  // Helper function to encode a double (64-bit float) to payload
  static Uint8List _encodeFloat64(double value) {
    final byteData = ByteData(8);
    byteData.setFloat64(0, value, Endian.big);
    return byteData.buffer.asUint8List();
  }

  // Helper function to decode a 64-bit float from payload
  static double _decodeFloat64(Uint8List payload) {
    final byteData = ByteData.sublistView(payload);
    return byteData.getFloat64(0, Endian.big);
  }
}

// void main() {
//   // Example usage of AvpFloat64 class
//   final avp = AvpFloat64(
//     code: 1,
//     flags: 0,
//     length: 16,
//     vendorId: 123,
//     value: 123.456, // Set initial value as double
//   );

//   print('Encoded value: ${avp.value}');
//   print('Decoded value: ${avp.value}');

//   avp.value = 789.123; // Update value
//   print('Updated decoded value: ${avp.value}');
// }
