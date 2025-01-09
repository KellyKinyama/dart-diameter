import 'dart:typed_data';
import 'dart:convert';

class OctetString {
  final List<int> value;

  OctetString(this.value);

  // Create a new OctetString instance
  factory OctetString.fromList(List<int> value) {
    return OctetString(value);
  }

  // Get the value as a list of bytes
  List<int> getValue() {
    return value;
  }

  // Decode an OctetString from a list of bytes
  static OctetString decodeFrom(Uint8List bytes) {
    return OctetString(List<int>.from(bytes));
  }

  // Encode the OctetString to a list of bytes
  Uint8List encodeTo() {
    return Uint8List.fromList(value);
  }

  // Return the length (in bytes)
  int length() {
    return value.length;
  }

  @override
  String toString() {
    return value
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }
}

void main() {
  // Test encoding and decoding
  final original = OctetString.fromList(
      [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);
  final encoded = original.encodeTo();
  print('Encoded: $encoded');

  final decoded = OctetString.decodeFrom(Uint8List.fromList(encoded));
  print('Decoded value: ${decoded.getValue()}');
  print('Decoded string: ${utf8.decode(decoded.getValue())}');
}
