import 'dart:typed_data';
import 'package:test/test.dart';

class AvpEncodeError implements Exception {
  final String message;
  AvpEncodeError(this.message);
}

class AvpDecodeError implements Exception {
  final String message;
  AvpDecodeError(this.message);
}

class AvpOctetString {
  final int code;
  Uint8List? _value;

  AvpOctetString(this.code);

  Uint8List get value => _value!;

  set value(dynamic newValue) {
    if (newValue is! Uint8List) {
      throw AvpEncodeError('Value must be bytes');
    }
    _value = newValue;
  }

  Uint8List asBytes() {
    return _value!;
  }
}

class AvpUtf8String {
  final int code;
  String? _value;
  late Uint8List payload;

  AvpUtf8String(this.code);

  String get value {
    try {
      return String.fromCharCodes(payload);
    } catch (e) {
      throw AvpDecodeError('Invalid UTF-8 encoded string');
    }
  }

  set value(dynamic newValue) {
    if (newValue is! String) {
      throw AvpEncodeError('Value must be a string');
    }
    _value = newValue;
    payload = Uint8List.fromList(newValue.codeUnits);
  }

  Uint8List asBytes() {
    return payload;
  }
}

void main() {
  group('AVP Error Handling', () {
    test('setting a non-byte value for OctetString throws AvpEncodeError', () {
      final a = AvpOctetString(123);

      expect(() => a.value = "secret", throwsA(isA<AvpEncodeError>()));
    });

    test('setting a non-string value for Utf8String throws AvpEncodeError', () {
      final a = AvpUtf8String(456);

      expect(() => a.value = 1, throwsA(isA<AvpEncodeError>()));
    });

    test('invalid UTF-16 payload for Utf8String throws AvpDecodeError', () {
      final a = AvpUtf8String(456);

      a.payload = Uint8List.fromList([0xFF, 0xFE, 0x49, 0x6C, 0xED, 0x8B]);

      expect(() => a.value, throwsA(isA<AvpDecodeError>()));
    });
  });
}
