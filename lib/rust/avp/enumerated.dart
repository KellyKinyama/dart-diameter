import 'dart:typed_data';
import 'dart:convert';

class Enumerated {
  final int value;

  Enumerated(this.value);

  // Create new Enumerated instance
  factory Enumerated.fromInt(int value) {
    return Enumerated(value);
  }

  // Get the value
  int getValue() {
    return value;
  }

  // Decode an Enumerated from a list of bytes
  static Enumerated decodeFrom(Uint8List bytes) {
    if (bytes.length < 4) {
      throw FormatException('Insufficient data for decoding');
    }
    final value = ByteData.sublistView(bytes).getInt32(0, Endian.big);
    return Enumerated(value);
  }

  // Encode the Enumerated to a list of bytes
  Uint8List encodeTo() {
    final bytes = ByteData(4)..setInt32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  // Return the length (4 bytes for an int32)
  int length() {
    return 4;
  }

  @override
  String toString() {
    return value.toString();
  }
}

void main() {
  // Example usage for encoding and decoding Enumerated

  final original = Enumerated.fromInt(-1234567890);
  final encoded = original.encodeTo();
  print('Encoded: $encoded');

  final decoded = Enumerated.decodeFrom(Uint8List.fromList(encoded));
  print('Decoded value: ${decoded.getValue()}');
}
