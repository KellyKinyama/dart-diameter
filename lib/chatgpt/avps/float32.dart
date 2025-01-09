import 'dart:typed_data';
import 'dart:convert';

import '../avp.dart';

class AvpFloat32 extends DiameterAVP {
  /// Constructor for AvpFloat32
  AvpFloat32({
    required int code,
    int flags = 0,
    int vendorId = 0,
  }) : super(
          code: code,
          flags: flags,
          length: 12, // Default AVP length for float values
          vendorId: vendorId,
          value: Uint8List(0), // Initialize with an empty value
        );

  /// Getter for the `value` as a float
  double get floatValue {
    if (value.length != 4) {
      throw Exception(
          "${name ?? 'Unknown'} value is not a valid 32-bit float.");
    }
    final byteData = ByteData.sublistView(value);
    return byteData.getFloat32(0, Endian.big);
  }

  /// Setter for the `value`
  set floatValue(double newValue) {
    final byteData = ByteData(4);
    try {
      byteData.setFloat32(0, newValue, Endian.big);
    } catch (e) {
      throw Exception(
          "${name ?? 'Unknown'} value $newValue is not a valid 32-bit float: $e");
    }
    value =
        byteData.buffer.asUint8List(); // Use the inherited setter for `value`
    length = value.length + 8; // Update AVP length (header + payload)
  }
}
