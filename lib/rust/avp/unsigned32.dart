import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class Unsigned32 {
  final int value;

  Unsigned32(this.value);

  // Create a new Unsigned32 instance
  factory Unsigned32.fromInt(int value) {
    return Unsigned32(value);
  }

  // Get the value
  int getValue() {
    return value;
  }

  // Decode an Unsigned32 from a stream
  static Unsigned32 decodeFrom(Uint8List data) {
    if (data.length < 4) {
      throw FormatException('Insufficient data for decoding');
    }
    final value =
        ByteData.sublistView(Uint8List.fromList(data)).getUint32(0, Endian.big);
    return Unsigned32(value);
  }

  // Encode the Unsigned32 to a stream
  Uint8List encodeTo() {
    final bytes = ByteData(4)..setUint32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  // Return the length (4 bytes for a u32)
  int length() {
    return 4;
  }

  @override
  String toString() {
    return value.toString();
  }
}

void main() async {
  // Test encoding and decoding
  final original = Unsigned32(1234567890);
  final encoded = original.encodeTo();
  final decoded = Unsigned32.decodeFrom(encoded);
  print('Decoded value: ${decoded.getValue()}');
}
