import 'dart:convert';
import 'dart:typed_data';

import '../avp.dart';

class AvpAddress extends DiameterAVP {
  AvpAddress({
    required int code,
    int flags = 0,
    int vendorId = 0,
  }) : super(
          code: code,
          flags: flags,
          length: 8, // Default length for AVP header
          vendorId: vendorId,
          value: Uint8List(0), // Initialize with an empty value
        );

  // Getter for parsed value
  Tuple<int, String> get parsedValue {
    if (value.isEmpty) {
      throw Exception("No payload available for decoding.");
    }

    final family = ByteData.sublistView(value, 0, 2).getUint16(0, Endian.big);
    final payload = value.sublist(2);

    switch (family) {
      case 1: // IPv4
        return Tuple(family, _decodeIPv4(payload));
      case 2: // IPv6
        return Tuple(family, _decodeIPv6(payload));
      case 8: // E.164
        return Tuple(family, utf8.decode(payload));
      default:
        throw Exception("Unsupported address family: $family");
    }
  }

  // Custom method to set the value
  void setValue(String newValue) {
    int family;
    Uint8List encodedPayload;

    if (RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(newValue)) {
      // IPv4
      family = 1;
      encodedPayload = _encodeIPv4(newValue);
    } else if (RegExp(r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$')
        .hasMatch(newValue)) {
      // IPv6
      family = 2;
      encodedPayload = _encodeIPv6(newValue);
    } else {
      // Default to E.164
      family = 8;
      encodedPayload = utf8.encode(newValue);
    }

    final buffer = BytesBuilder();
    buffer.add(
        Uint8List(2)..buffer.asByteData().setUint16(0, family, Endian.big));
    buffer.add(encodedPayload);

    super.value = buffer.toBytes(); // Use the inherited setter for `value`
    length = value.length + 8; // Update AVP length
  }

  // Helper to encode IPv4 address
  Uint8List _encodeIPv4(String address) {
    final parts = address.split('.').map(int.parse).toList();
    if (parts.length != 4 || parts.any((part) => part < 0 || part > 255)) {
      throw Exception("Invalid IPv4 address: $address");
    }
    return Uint8List.fromList(parts);
  }

  // Helper to encode IPv6 address
  Uint8List _encodeIPv6(String address) {
    final parts = address.split(':');
    if (parts.length != 8) {
      throw Exception("Invalid IPv6 address: $address");
    }

    final buffer = BytesBuilder();
    for (var part in parts) {
      final value = int.parse(part, radix: 16);
      final bytes = Uint8List(2);
      bytes.buffer.asByteData().setUint16(0, value, Endian.big);
      buffer.add(bytes);
    }

    return buffer.toBytes();
  }

  // Helper to decode IPv4 address
  String _decodeIPv4(Uint8List payload) {
    if (payload.length != 4) {
      throw Exception("Invalid IPv4 payload length: ${payload.length}");
    }
    return payload.map((byte) => byte.toString()).join('.');
  }

  // Helper to decode IPv6 address
  String _decodeIPv6(Uint8List payload) {
    if (payload.length != 16) {
      throw Exception("Invalid IPv6 payload length: ${payload.length}");
    }
    final segments = <String>[];
    for (int i = 0; i < payload.length; i += 2) {
      final segment = payload.buffer.asByteData().getUint16(i, Endian.big);
      segments.add(segment.toRadixString(16));
    }
    return segments.join(':');
  }
}

// Utility class to hold a tuple of two values
class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple(this.item1, this.item2);
}

void main() {
  final avpAddress = AvpAddress(code: 123);

  // Set and get IPv4 address
  avpAddress.setValue("193.16.219.96");
  print(avpAddress.parsedValue); // Output: Tuple(1, "193.16.219.96")

  // Set and get IPv6 address
  avpAddress.setValue("8b71:8c8a:1e29:716a:6184:7966:fd43:4200");
  print(avpAddress
      .parsedValue); // Output: Tuple(2, "8b71:8c8a:1e29:716a:6184:7966:fd43:4200")

  // Set and get E.164 address
  avpAddress.setValue("48507909008");
  print(avpAddress.parsedValue); // Output: Tuple(8, "48507909008")
}
