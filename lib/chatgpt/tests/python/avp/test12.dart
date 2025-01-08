import 'package:test/test.dart';
import 'dart:typed_data';

class AvpDecodeError implements Exception {
  final String message;
  AvpDecodeError(this.message);
}

class Avp {
  static Avp fromBytes(Uint8List bytes) {
    if (bytes.length < 16) {
      throw AvpDecodeError('Payload is too short');
    }
    // Add additional decoding logic here if needed
    // For now, this is a simple example, assuming AVP should be at least 16 bytes long.
    return Avp();
  }
}

void main() {
  group('AVP decoding errors', () {
    test('decoding from incomplete bytes throws AvpDecodeError', () {
      final avpBytes = Uint8List.fromList([
        0x00, 0x00, 0x01, 0xcd, 0x40, 0x00, 0x00, 0x16,
        0x33, 0x32, 0x32, 0x35, 0x31, 0x40, 0x36, 0x67,
        0x70, 0x70, 0x2e, 0x60 // Payload is cut off here
      ]);

      expect(() => Avp.fromBytes(avpBytes), throwsA(isA<AvpDecodeError>()));
    });
  });
}
