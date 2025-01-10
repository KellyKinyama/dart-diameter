import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../avp8.dart';

// Define the base AVP class

abstract class AddressAVP extends AVP {
  final AddressValue addressValue;

  AddressAVP(this.addressValue);

  // Create new AddressAVP instances for each type
  factory AddressAVP.fromIPv4(InternetAddress ip) {
    return IPv4AVP(ip);
  }

  factory AddressAVP.fromIPv6(InternetAddress ip) {
    return IPv6AVP(ip);
  }

  factory AddressAVP.fromE164(String str) {
    return E164AVP(str);
  }

  static AddressAVP decodeFrom(Uint8List bytes, int len) {
    final b = bytes.sublist(0, 2); // First two bytes for address type

    final addressValue = _decodeAddress(b, bytes.sublist(2), len);
    if (addressValue is IPv4) {
      return IPv4AVP(addressValue.ip);
    } else if (addressValue is IPv6) {
      return IPv6AVP(addressValue.ip);
    } else if (addressValue is E164) {
      return E164AVP(addressValue.str);
    } else {
      throw FormatException('Unsupported address type');
    }
  }

  static AddressValue _decodeAddress(
      List<int> b, List<int> remainingBytes, int len) {
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

  // Encode the AddressAVP to a byte array
  List<int> encodeTo() {
    final bytes = <int>[];

    if (addressValue is IPv4) {
      bytes.addAll([0, 1]);
      final ip = (addressValue as IPv4).ip;
      bytes.addAll(ip.address.codeUnits);
    } else if (addressValue is IPv6) {
      bytes.addAll([0, 2]);
      final ip = (addressValue as IPv6).ip;
      bytes.addAll(ip.rawAddress);
    } else if (addressValue is E164) {
      bytes.addAll([0, 8]);
      final str = (addressValue as E164).str;
      bytes.addAll(str.codeUnits);
    }

    return bytes;
  }

  @override
  String toString() {
    return addressValue.toString();
  }
}

class IPv4AVP extends AddressAVP {
  IPv4AVP(InternetAddress ip) : super(IPv4(ip));

  @override
  Uint8List get value {
    final ip = (addressValue as IPv4).ip;
    return Uint8List.fromList(ip.address.codeUnits);
  }
}

class IPv6AVP extends AddressAVP {
  IPv6AVP(InternetAddress ip) : super(IPv6(ip));

  @override
  Uint8List get value {
    final ip = (addressValue as IPv6).ip;
    return ip.rawAddress;
  }
}

class E164AVP extends AddressAVP {
  E164AVP(String str) : super(E164(str));

  @override
  Uint8List get value {
    final str = (addressValue as E164).str;
    return Uint8List.fromList(str.codeUnits);
  }
}

// Define the AddressValue class and its subclasses
abstract class AddressValue {}

class IPv4 extends AddressValue {
  final InternetAddress ip;
  IPv4(this.ip);

  @override
  String toString() {
    return ip.address;
  }
}

class IPv6 extends AddressValue {
  final InternetAddress ip;
  IPv6(this.ip);

  @override
  String toString() {
    return ip.address;
  }
}

class E164 extends AddressValue {
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

  final ipv4AVP = AddressAVP.fromIPv4(ipv4Addr);
  final ipv6AVP = AddressAVP.fromIPv6(ipv6Addr);
  final e164AVP = AddressAVP.fromE164(e164Addr);

  // Encode to byte arrays
  final encodedIpv4 = ipv4AVP.encodeTo();
  final encodedIpv6 = ipv6AVP.encodeTo();
  final encodedE164 = e164AVP.encodeTo();

  print('Encoded IPv4 AVP: $encodedIpv4');
  print('Encoded IPv6 AVP: $encodedIpv6');
  print('Encoded E164 AVP: $encodedE164');

  // Decode from byte arrays
  final decodedIpv4 = AddressAVP.decodeFrom(Uint8List.fromList(encodedIpv4), 6);
  final decodedIpv6 =
      AddressAVP.decodeFrom(Uint8List.fromList(encodedIpv6), 18);
  final decodedE164 =
      AddressAVP.decodeFrom(Uint8List.fromList(encodedE164), 14);

  print('Decoded IPv4 AVP: ${decodedIpv4.toString()}');
  print('Decoded IPv6 AVP: ${decodedIpv6.toString()}');
  print('Decoded E164 AVP: ${decodedE164.toString()}');
}
