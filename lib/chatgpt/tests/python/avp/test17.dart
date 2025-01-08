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

class Avp {
  final int code;
  Uint8List _payload;

  Avp(this.code, {Uint8List? payload}) : _payload = payload ?? Uint8List(0);

  set payload(dynamic newPayload) {
    if (newPayload is String) {
      throw AvpEncodeError("Payload must be bytes, not a string.");
    }
    _payload = newPayload;
  }

  dynamic get value {
    try {
      // Decoding payload to a desired value.
      return _payload;
    } catch (e) {
      throw AvpDecodeError("Failed to decode AVP value.");
    }
  }

  Uint8List asBytes() {
    return _payload;
  }

  static Avp fromBytes(Uint8List bytes) {
    // Simulating byte parsing (here you'd use actual AVP parsing logic)
    return Avp(0, payload: bytes);
  }
}

class AvpGrouped extends Avp {
  List<Avp> _avps = [];

  AvpGrouped(int code) : super(code);

  @override
  set value(List<Avp> newAvps) {
    for (var avp in newAvps) {
      if (avp is! Avp) {
        throw AvpEncodeError('Grouped value must contain AVP instances only.');
      }
    }
    _avps = newAvps;
  }

  @override
  List<Avp> get value => _avps;
}

void main() {
  group('AVP Grouped Type Error Handling', () {
    test(
        'assign an AVP with a junk payload, grouped AVP must contain AVP instances only',
        () {
      final ag = AvpGrouped(123);
      final at = Avp(456);
      at.payload = Uint8List.fromList([1, 2, 3]);

      ag.value = [at];

      // Assign an invalid payload to `at`
      expect(() => at.payload = "invalid", throwsA(isA<AvpEncodeError>()));
    });

    test('inject junk into the grouped AVP portion', () {
      final ag = AvpGrouped(123);
      final at = Avp(456);
      at.payload = Uint8List.fromList([1, 2, 3]);

      ag.value = [at];

      // Simulate junk byte injection
      final newAg = Avp.fromBytes(Uint8List.fromList(
          ag.asBytes().sublist(0, ag.asBytes().length - 6) +
              Uint8List.fromList([0, 0]) +
              ag.asBytes().sublist(ag.asBytes().length - 6)));

      expect(() => newAg.value, throwsA(isA<AvpDecodeError>()));
    });
  });
}
