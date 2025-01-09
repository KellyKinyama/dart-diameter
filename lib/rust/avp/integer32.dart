import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class Integer32 {
  final int value;

  Integer32(this.value);

  // Create a new Integer32 instance
  factory Integer32.fromInt(int value) {
    return Integer32(value);
  }

  // Get the value
  int getValue() {
    return value;
  }

  // Decode an Integer32 from a stream
  static Integer32 decodeFrom(Uint8List data) {
    if (data.length < 4) {
      throw FormatException('Insufficient data for decoding');
    }
    final value =
        ByteData.sublistView(Uint8List.fromList(data)).getInt32(0, Endian.big);
    return Integer32(value);
  }

  // Encode the Integer32 to a stream
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

void main() async {
  // Test encoding and decoding
  final original = Integer32(-1234567890);
  final encoded = original.encodeTo();
  final decoded = Integer32.decodeFrom(encoded);
  print('Decoded value: ${decoded.getValue()}');
}
