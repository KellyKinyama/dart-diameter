import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

// Simulating UTF8String class in Dart
class UTF8String {
  final String value;

  UTF8String(this.value);

  // Constructor to create a UTF8String from a raw byte list
  factory UTF8String.decodeFrom(Uint8List data) {
    final decodedValue = utf8.decode(data);
    return UTF8String(decodedValue);
  }

  // Encode the UTF8String to a byte list
  Uint8List encodeTo() {
    return utf8.encode(value) as Uint8List;
  }

  // Return the length of the UTF8String in bytes
  int length() {
    return utf8.encode(value).length;
  }

  // String value() {
  //   return value;
  // }

  @override
  String toString() {
    return value;
  }
}

// Identity class that wraps around UTF8String
class Identity {
  final UTF8String identity;

  Identity(this.identity);

  // Create a new Identity from a string
  factory Identity.newIdentity(String value) {
    return Identity(UTF8String(value));
  }

  String value() {
    return identity.value;
  }

  // Decode Identity from a reader (using byte list here)
  static Identity decodeFrom(Uint8List data) {
    final utf8String = UTF8String.decodeFrom(data);
    return Identity(utf8String);
  }

  // Encode Identity to byte list
  void encodeTo(List<int> writer) {
    final encodedData = identity.encodeTo();
    writer.addAll(encodedData);
  }

  int length() {
    return identity.length();
  }

  @override
  String toString() {
    return identity.toString();
  }
}

void main() {
  // Test encoding and decoding
  final identity = Identity.newIdentity("example.com");

  // Encode to byte list
  final encoded = <int>[];
  identity.encodeTo(encoded);
  print('Encoded: $encoded');

  // Decode from byte list
  final decoded = Identity.decodeFrom(Uint8List.fromList(encoded));
  print('Decoded: ${decoded.value()}');
}
