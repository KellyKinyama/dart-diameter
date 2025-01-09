import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class UTF8String {
  final String value;

  UTF8String(this.value);

  // Create a new UTF8String instance
  factory UTF8String.fromString(String value) {
    return UTF8String(value);
  }

  // Get the value
  String getValue() {
    return value;
  }

  // Decode a UTF8String from a stream
  static UTF8String decodeFrom(Uint8List data) {
    try {
      final decodedString = utf8.decode(data);
      return UTF8String(decodedString);
    } catch (e) {
      throw FormatException('invalid UTF8String: $e');
    }
  }

  // Encode the UTF8String to a stream
  Uint8List encodeTo() {
    return Uint8List.fromList(utf8.encode(value));
  }

  // Return the length (in bytes) of the UTF8 string
  int length() {
    return utf8.encode(value).length;
  }

  @override
  String toString() {
    return value;
  }
}

void main() async {
  // Test encoding and decoding
  final original = UTF8String.fromString("Hello World");
  final encoded = original.encodeTo();
  final decoded = UTF8String.decodeFrom(encoded);
  print('Decoded value: ${decoded.getValue()}');
}
