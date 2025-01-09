import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class Unsigned64 {
  final int value;

  Unsigned64(this.value);

  // Create a new Unsigned64 instance
  factory Unsigned64.fromInt(int value) {
    return Unsigned64(value);
  }

  // Get the value
  int getValue() {
    return value;
  }

  // Decode an Unsigned64 from a stream
  static Unsigned64 decodeFrom(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Insufficient data for decoding');
    }
    final value =
        ByteData.sublistView(Uint8List.fromList(data)).getUint64(0, Endian.big);
    return Unsigned64(value);
  }

  // Encode the Unsigned64 to a stream
  Uint8List encodeTo() {
    final bytes = ByteData(8)..setUint64(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  // Return the length (8 bytes for a u64)
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
  final original = Unsigned64(123456789000000000);
  final encoded = original.encodeTo();
  final decoded = Unsigned64.decodeFrom(encoded);
  print('Decoded value: ${decoded.getValue()}');
}
