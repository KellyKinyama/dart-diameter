import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Address {
  final Value value;

  Address(this.value);

  // Create new Address instances for each type
  factory Address.fromIPv4(InternetAddress ip) {
    return Address(IPv4(ip));
  }

  factory Address.fromIPv6(InternetAddress ip) {
    return Address(IPv6(ip));
  }

  factory Address.fromE164(String str) {
    return Address(E164(str));
  }

  // Decode an Address from a byte array
  static Address decodeFrom(Uint8List bytes, int len) {
    final b = bytes.sublist(0, 2); // First two bytes for address type

    final value = _decodeAddress(b, bytes.sublist(2), len);
    return Address(value);
  }

  static Value _decodeAddress(List<int> b, List<int> remainingBytes, int len) {
    if (b[0] == 0 && b[1] == 1) {
      // IPv4 address
      if (len != 6) {
        throw FormatException('Invalid IPv4 address length');
      }
      final ipBytes = remainingBytes.sublist(0, 4); // First 4 bytes for IPv4
      final ip = InternetAddress(ipBytes.join('.'));
      return IPv4(ip);
    } else if (b[0] == 0 && b[1] == 2) {
      // IPv6 address
      if (len != 18) {
        throw FormatException('Invalid IPv6 address length');
      }
      if (remainingBytes.length < 16) {
        throw FormatException('Invalid IPv6 address bytes');
      }
      final ipBytes = remainingBytes.sublist(0, 16); // First 16 bytes for IPv6
      final ip = InternetAddress.fromRawAddress(Uint8List.fromList(ipBytes));
      return IPv6(ip);
    } else if (b[0] == 0 && b[1] == 8) {
      // E.164 address
      if (len > 17 || len < 3) {
        throw FormatException('Invalid E.164 address length');
      }
      final strBytes =
          remainingBytes.sublist(0, len - 2); // Ensure valid length
      final str = String.fromCharCodes(strBytes);
      return E164(str);
    } else {
      throw FormatException('Unsupported address type');
    }
  }

  // Encode the Address to a byte array
  List<int> encodeTo() {
    final bytes = <int>[];

    if (value is IPv4) {
      bytes.addAll([0, 1]);
      final ip = (value as IPv4).ip;
      bytes.addAll(ip.address.codeUnits);
    } else if (value is IPv6) {
      bytes.addAll([0, 2]);
      final ip = (value as IPv6).ip;
      bytes.addAll(ip.rawAddress);
    } else if (value is E164) {
      bytes.addAll([0, 8]);
      final str = (value as E164).str;
      bytes.addAll(str.codeUnits);
    }

    return bytes;
  }

  // Get the length of the Address
  int length() {
    if (value is IPv4) {
      return 6;
    } else if (value is IPv6) {
      return 18;
    } else if (value is E164) {
      return (value as E164).str.length;
    } else {
      return 0;
    }
  }

  @override
  String toString() {
    return value.toString();
  }
}

abstract class Value {
  Value();
}

class IPv4 extends Value {
  final InternetAddress ip;
  IPv4(this.ip);

  @override
  String toString() {
    return ip.address;
  }
}

class IPv6 extends Value {
  final InternetAddress ip;
  IPv6(this.ip);

  @override
  String toString() {
    return ip.address;
  }
}

class E164 extends Value {
  final String str;
  E164(this.str);

  @override
  String toString() {
    return str;
  }
}

void main() {
  // Example usage for encoding and decoding addresses

  final ipv4Addr = InternetAddress('127.0.0.1');
  final ipv6Addr = InternetAddress('::1');
  final e164Addr = "359898000135";

  final ipv4Address = Address.fromIPv4(ipv4Addr);
  final ipv6Address = Address.fromIPv6(ipv6Addr);
  final e164Address = Address.fromE164(e164Addr);

  // Encode to byte arrays
  final encodedIpv4 = ipv4Address.encodeTo();
  final encodedIpv6 = ipv6Address.encodeTo();
  final encodedE164 = e164Address.encodeTo();

  print('Encoded IPv4: $encodedIpv4');
  print('Encoded IPv6: $encodedIpv6');
  print('Encoded E164: $encodedE164');

  // Decode from byte arrays
  final decodedIpv4 = Address.decodeFrom(Uint8List.fromList(encodedIpv4), 6);
  final decodedIpv6 = Address.decodeFrom(Uint8List.fromList(encodedIpv6), 18);
  final decodedE164 = Address.decodeFrom(Uint8List.fromList(encodedE164), 14);

  print('Decoded IPv4: ${decodedIpv4.toString()}');
  print('Decoded IPv6: ${decodedIpv6.toString()}');
  print('Decoded E164: ${decodedE164.toString()}');
}
