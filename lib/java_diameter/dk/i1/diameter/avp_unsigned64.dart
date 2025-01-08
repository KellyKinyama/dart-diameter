import 'dart:typed_data';
import 'avp.dart';
import 'avp_unsinged32.dart';
import 'utils.dart';

class AVP_Unsigned64 extends AVP {
  AVP_Unsigned64(AVP a) : super.copy(a) {
    // Assuming super.copy(a) is available
    if (a.queryPayloadSize() != 8) {
      throw InvalidAVPLengthException(a); // Check if payload size is 8
    }
  }

  AVP_Unsigned64.intValue(int code, int value)
      : super.withPayload(
            code,
            Uint8List.fromList(
                _longToByte(value))); // Adjusted to use withPayload

  AVP_Unsigned64.vendorValue(int code, int vendorId, int value)
      : super.withVendor(
            code,
            vendorId,
            Uint8List.fromList(
                _longToByte(value))); // Adjusted to use withVendor

  int queryValue() {
    return _unpack64(payload, 0); // Extract the 64-bit value from payload
  }

  void setValue(int value) {
    _pack64(payload, 0, value); // Pack the 64-bit value into the payload
  }

  static List<int> _longToByte(int value) {
    return _pack64(List<int>.filled(8, 0), 0, value); // Convert to byte array
  }

  static int _unpack64(List<int> data, int offset) {
    return ByteData.sublistView(Uint8List.fromList(data))
            .getInt64(offset, Endian.big) &
        0xFFFFFFFFFFFFFFFF; // Extract 64-bit integer
  }

  static List<int> _pack64(List<int> data, int offset, int value) {
    ByteData.sublistView(Uint8List.fromList(data)).setInt64(
        offset, value, Endian.big); // Store 64-bit integer in byte array
    return data;
  }
}
