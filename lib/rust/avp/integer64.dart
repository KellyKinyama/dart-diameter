import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class Integer64 {
  final int value;

  Integer64(this.value);

  // Create a new Integer64 instance
  factory Integer64.fromInt(int value) {
    return Integer64(value);
  }

  // Get the value
  int getValue() {
    return value;
  }

  // Decode an Integer64 from a stream
  static Integer64 decodeFrom(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Insufficient data for decoding');
    }
    final value =
        ByteData.sublistView(Uint8List.fromList(data)).getInt64(0, Endian.big);
    return Integer64(value);
  }

  // Encode the Integer64 to a stream
  Uint8List encodeTo() {
    final bytes = ByteData(8)..setInt64(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  // Return the length (8 bytes for an int64)
  int length() {
    return 8;
  }

  @override
  String toString() {
    return value.toString();
  }
}

void main() async {
  // Test encoding and decoding
  final original = Integer64(-123456789000000000);
  final encoded = original.encodeTo();
  final decoded = Integer64.decodeFrom(encoded);
  print('Decoded value: ${decoded.getValue()}');
}
