import 'package:test/test.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:core';

class AvpEncodeError implements Exception {
  final String message;
  AvpEncodeError(this.message);
}

class AvpAddress {
  final int code;
  String _value;

  AvpAddress(this.code) : _value = "";

  String get value => _value;

  set value(String v) {
    if (_isInvalidAddress(v)) {
      throw AvpEncodeError("Invalid address type");
    }
    _value = v;
  }

  bool _isInvalidAddress(String address) {
    // Check for IPv4 address (simple version)
    if (_isIpv4(address)) {
      return false;
    }

    // Check for IPv6 address (simple version)
    if (_isIpv6(address)) {
      return false;
    }

    // For E.164, it should be a valid UTF-8 string (this check is simplified)
    if (_isE164(address)) {
      return false;
    }

    return true; // If none of the checks pass, it's invalid
  }

  bool _isIpv4(String address) {
    // Simple check for IPv4 address format (not exhaustive)
    var parts = address.split('.');
    if (parts.length == 4) {
      for (var part in parts) {
        var n = int.tryParse(part);
        if (n == null || n < 0 || n > 255) return false;
      }
      return true;
    }
    return false;
  }

  bool _isIpv6(String address) {
    // Simple check for IPv6 address format (not exhaustive)
    var regex =
        RegExp(r'^[0-9a-fA-F:]+$'); // Matches only hex characters and colons
    return regex.hasMatch(address);
  }

  bool _isE164(String address) {
    // Check if it's a valid UTF-8 string for E.164 format
    try {
      utf8.encode(address);
      return true;
    } catch (e) {
      return false;
    }
  }
}

void main() {
  group('AvpAddress tests', () {
    test('invalid IPv4 address throws AvpEncodeError', () {
      final a = AvpAddress(123); // Example AVP code
      expect(() => a.value = "193.16.219.960", throwsA(isA<AvpEncodeError>()));
    });

    test('invalid IPv6 address throws AvpEncodeError', () {
      final a = AvpAddress(123); // Example AVP code
      expect(() => a.value = "8b71:8c8a:1e29:716a:6184:7966:fd43",
          throwsA(isA<AvpEncodeError>()));
    });

    test(
        'E.164 format accepts anything as a UTF-8 string, throws error for non-string',
        () {
      final a = AvpAddress(123); // Example AVP code
      expect(() => a.value = "1", throwsA(isA<AvpEncodeError>()));
    });
  });
}
