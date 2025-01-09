import 'dart:typed_data';
import 'dart:io';

class OctetString {
  final List<int> value;

  OctetString(this.value);

  // Create a new OctetString instance
  factory OctetString.fromBytes(List<int> value) {
    return OctetString(value);
  }

  // Get the value of OctetString
  List<int> getValue() {
    return value;
  }

  // Decode an OctetString from a stream
  static OctetString decodeFrom(List<int> data) {
    return OctetString(data);
  }

  // Encode the OctetString to a stream
  void encodeTo(List<int> writer) {
    writer.addAll(value);
  }

  // Return the length of OctetString
  int length() {
    return value.length;
  }
}

class DiameterURI {
  final OctetString octetString;

  DiameterURI(List<int> value) : octetString = OctetString.fromBytes(value);

  // Get the value of DiameterURI
  List<int> getValue() {
    return octetString.getValue();
  }

  // Decode a DiameterURI from a stream
  static DiameterURI decodeFrom(List<int> data) {
    final octetString = OctetString.decodeFrom(data);
    return DiameterURI(octetString.getValue());
  }

  // Encode the DiameterURI to a stream
  void encodeTo(List<int> writer) {
    octetString.encodeTo(writer);
  }

  // Return the length of DiameterURI
  int length() {
    return octetString.length();
  }

  @override
  String toString() {
    return octetString
        .getValue()
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }
}

void main() {
  final diameterUri = DiameterURI([0x30, 0x31, 0x32, 0x33, 0x34]);
  print('DiameterURI: $diameterUri');

  final encoded = <int>[];
  diameterUri.encodeTo(encoded);
  print('Encoded: $encoded');

  final decoded = DiameterURI.decodeFrom(encoded);
  print('Decoded: $decoded');
}
