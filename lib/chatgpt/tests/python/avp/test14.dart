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

class AvpInteger32 {
  final int code;
  int? _value;

  AvpInteger32(this.code);

  int get value => _value!;

  set value(dynamic newValue) {
    if (newValue is! int) {
      throw AvpEncodeError('Value must be an integer');
    }
    if (newValue < -2147483648 || newValue > 2147483647) {
      throw AvpEncodeError('Value is too large for a 32-bit integer');
    }
    _value = newValue;
  }

  Uint8List asBytes() {
    final ByteData byteData = ByteData(4);
    byteData.setInt32(0, _value!, Endian.little);
    return byteData.buffer.asUint8List();
  }
}

class AvpUnsigned32 {
  final int code;
  int? _value;

  AvpUnsigned32(this.code);

  int get value => _value!;

  set value(dynamic newValue) {
    if (newValue is! int) {
      throw AvpEncodeError('Value must be an integer');
    }
    if (newValue < 0) {
      throw AvpEncodeError('Value must be a positive integer');
    }
    _value = newValue;
  }

  Uint8List asBytes() {
    final ByteData byteData = ByteData(4);
    byteData.setUint32(0, _value!, Endian.little);
    return byteData.buffer.asUint8List();
  }
}

class AvpUnsigned64 {
  final int code;
  BigInt? _value; // Use BigInt for larger values

  AvpUnsigned64(this.code);

  BigInt get value => _value!;

  set value(dynamic newValue) {
    if (newValue is! BigInt && newValue is! int) {
      throw AvpEncodeError('Value must be an integer');
    }
    if (newValue is int) {
      newValue = BigInt.from(newValue); // Convert int to BigInt
    }
    if (newValue.isNegative) {
      throw AvpEncodeError('Value must be a positive integer');
    }
    _value = newValue;
  }

  Uint8List asBytes() {
    final ByteData byteData = ByteData(8);
    byteData.setUint64(
        0, _value!.toInt(), Endian.little); // Convert BigInt to int
    return byteData.buffer.asUint8List();
  }
}

void main() {
  group('AVP Integer type error handling', () {
    test('setting a too large value for Integer32 throws AvpEncodeError', () {
      final a = AvpInteger32(123);

      // Use BigInt for large numbers like 17347878958773879024
      expect(
          () => a.value = 17347878958773879024, throwsA(isA<AvpEncodeError>()));
    });

    test('setting a non-integer value for Integer32 throws AvpEncodeError', () {
      final a = AvpInteger32(123);

      expect(() => a.value = "some string", throwsA(isA<AvpEncodeError>()));
    });

    test('setting a negative value for Unsigned32 throws AvpEncodeError', () {
      final a = AvpUnsigned32(456);

      expect(() => a.value = -1, throwsA(isA<AvpEncodeError>()));
    });

    test('setting a negative value for Unsigned64 throws AvpEncodeError', () {
      final a = AvpUnsigned64(789);

      // Use BigInt for large numbers
      expect(() => a.value = BigInt.from(-17347878958773879024),
          throwsA(isA<AvpEncodeError>()));
    });

    test('creating an Unsigned32 AVP with signed value throws AvpDecodeError',
        () {
      final a = AvpUnsigned32(456);

      expect(() => a.asBytes(), throwsA(isA<AvpDecodeError>()));
    });
  });
}
