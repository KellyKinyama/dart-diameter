import 'package:test/test.dart';
import 'dart:typed_data';

class AvpEncodeError implements Exception {
  final String message;
  AvpEncodeError(this.message);
}

class AvpDecodeError implements Exception {
  final String message;
  AvpDecodeError(this.message);
}

class AvpFloat32 {
  final int code;
  Uint8List _payload = Uint8List(0);
  double? _value;

  AvpFloat32(this.code);

  // Getter for value, will attempt to decode the payload as a 32-bit float.
  double get value {
    if (_payload.length != 4) {
      throw AvpDecodeError('Payload is not a valid 32-bit float');
    }
    return _decodeFloat32(_payload);
  }

  // Setter for value, will attempt to encode the double into a 32-bit float.
  set value(dynamic value) {
    if (value is! double) {
      throw AvpEncodeError('Value must be a float');
    }
    _payload = _encodeFloat32(value);
  }

  // Method to encode a double into a 32-bit float (IEEE 754 format).
  Uint8List _encodeFloat32(double value) {
    final ByteData byteData = ByteData(4);
    byteData.setFloat32(0, value, Endian.little);
    return byteData.buffer.asUint8List();
  }

  // Method to decode a 32-bit float from the payload.
  double _decodeFloat32(Uint8List payload) {
    final ByteData byteData = ByteData.sublistView(payload);
    return byteData.getFloat32(0, Endian.little);
  }

  // Setter for payload directly
  set payload(Uint8List data) {
    _payload = data;
  }
}

void main() {
  group('AVP Float32 error handling', () {
    test('setting a non-float value throws AvpEncodeError', () {
      final a = AvpFloat32(123); // Assuming 123 is a valid AVP code

      expect(() => a.value = "128.65", throwsA(isA<AvpEncodeError>()));
    });

    test('malformed payload throws AvpDecodeError', () {
      final a = AvpFloat32(123);
      a.payload = Uint8List.fromList(
          [0x43, 0x00, 0xa6, 0x66, 0x00]); // Invalid 32-bit float payload

      expect(() => a.value, throwsA(isA<AvpDecodeError>()));
    });
  });
}
