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

class AvpTime {
  final int code;
  DateTime? _value;
  late Uint8List _payload;

  AvpTime(this.code);

  DateTime get value => _value!;

  set value(dynamic newValue) {
    if (newValue is! DateTime) {
      throw AvpEncodeError('Value must be a DateTime instance');
    }
    _value = newValue;
  }

  Uint8List asBytes() {
    // Convert the DateTime to a suitable byte representation, assuming NTP time.
    final timestamp =
        _value!.millisecondsSinceEpoch ~/ 1000; // seconds precision
    return Uint8List(8)..buffer.asByteData().setInt64(0, timestamp);
  }

  set payload(Uint8List newPayload) {
    if (newPayload.length != 8) {
      throw AvpDecodeError('Invalid payload size for time');
    }
    _payload = newPayload;
    final timestamp = ByteData.sublistView(newPayload).getInt64(0);
    _value = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  Uint8List get payloadBytes => _payload;
}

void main() {
  group('AVP Time Type Error Handling', () {
    test('must be DateTime instances', () {
      final a = AvpTime(123);

      expect(() => a.value = DateTime.now().millisecondsSinceEpoch,
          throwsA(isA<AvpEncodeError>()));
      expect(() => a.value = "2023-08-25 00:34:12",
          throwsA(isA<AvpEncodeError>()));
    });

    test('64-bit integer in payload is not valid', () {
      final a = AvpTime(123);
      a.payload = Uint8List.fromList([0, 0, 0, 1, 0, 0, 0, 1]);

      expect(() => a.value, throwsA(isA<AvpDecodeError>()));
    });

    test('dates before 1968 cannot be represented', () {
      final a = AvpTime(123);
      a.value = DateTime(1968, 1, 16, 6, 28, 15);

      expect(a.value.isBefore(DateTime(1968, 1, 16, 6, 28, 15)), isTrue);
    });

    test('dates past 2104 cannot be represented', () {
      final a = AvpTime(123);
      a.value = DateTime(2105, 2, 7, 6, 28, 17);

      expect(a.value.isAfter(DateTime(2105, 2, 7, 6, 28, 17)), isTrue);
    });
  });
}
