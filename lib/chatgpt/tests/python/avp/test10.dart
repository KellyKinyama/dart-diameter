import 'dart:typed_data';

// Simulate the AvpGrouped, AvpUnsigned32, AvpUtf8String, and constants for this example
class AvpGrouped {
  final int code;
  List<Avp> _value;
  Uint8List _payload;

  AvpGrouped(this.code)
      : _value = [],
        _payload = Uint8List(0);

  List<Avp> get value => _value;

  set value(List<Avp> v) {
    _value = v;
    List<int> combinedBytes = [];
    for (var avp in _value) {
      combinedBytes.addAll(avp.asBytes());
    }
    _payload = Uint8List.fromList(combinedBytes);
  }

  Uint8List get payload => _payload;
}

class Avp {
  final int code;
  Uint8List _payload;

  Avp(this.code) : _payload = Uint8List(0);

  // Each subclass will implement its own asBytes method
  Uint8List asBytes() => _payload;

  static Avp newAvp(int code, int vendor) {
    if (vendor != 123) {
      // Example vendor check
      throw ValueError("Vendor mismatch");
    }
    return Avp(code);
  }
}

class AvpUnsigned32 extends Avp {
  int _value;

  AvpUnsigned32(int code)
      : _value = 0,
        super(code);

  int get value => _value;

  set value(int v) {
    _value = v;
    _payload = Uint8List(4);
    _payload.buffer.asByteData().setUint32(0, _value);
  }

  @override
  Uint8List asBytes() => _payload;
}

class AvpUtf8String extends Avp {
  String _value;

  AvpUtf8String(int code)
      : _value = '',
        super(code);

  String get value => _value;

  set value(String v) {
    _value = v;
    _payload = Uint8List.fromList(v.codeUnits);
  }

  @override
  Uint8List asBytes() => _payload;
}

class ValueError implements Exception {
  final String message;
  ValueError(this.message);
}

void testCreateGroupedType() {
  final ag = AvpGrouped(1); // Example AVP code for SUBSCRIPTION_ID

  final at = AvpUnsigned32(2); // Example AVP code for SUBSCRIPTION_ID_TYPE
  at.value = 0;

  final ad = AvpUtf8String(3); // Example AVP code for SUBSCRIPTION_ID_DATA
  ad.value = "485079164547";

  ag.value = [at, ad];

  assert(ag.value == [at, ad]);
  assert(ag.payload == Uint8List.fromList(at.asBytes() + ad.asBytes()));

  print("testCreateGroupedType passed");
}

void testErrorAvpVendorMismatch() {
  try {
    Avp.newAvp(4, 999); // Vendor mismatch
  } catch (e) {
    if (e is ValueError) {
      print("testErrorAvpVendorMismatch passed: $e");
    } else {
      print("testErrorAvpVendorMismatch failed: Unexpected error $e");
    }
  }
}

void main() {
  testCreateGroupedType();
  testErrorAvpVendorMismatch();
}
