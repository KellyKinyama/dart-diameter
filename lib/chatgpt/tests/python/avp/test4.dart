import 'dart:typed_data';

class AvpUnsigned32 {
  final int code;
  int _value = 0;

  AvpUnsigned32(this.code);

  // Getter for the value
  int get value => _value;

  // Setter for the value
  set value(int v) {
    if (v < 0 || v > 0xFFFFFFFF) {
      throw ArgumentError("Value out of range for Unsigned32.");
    }
    _value = v;
  }

  // Compute payload
  Uint8List get payload {
    final buffer = ByteData(4);
    buffer.setUint32(0, _value, Endian.big);
    return buffer.buffer.asUint8List();
  }
}

class AvpUnsigned64 {
  final int code;
  BigInt _value = BigInt.zero;

  AvpUnsigned64(this.code);

  // Getter for the value
  BigInt get value => _value;

  // Setter for the value
  set value(BigInt v) {
    // if (v < BigInt.zero || v > BigInt.from(0xFFFFFFFFFFFFFFFF)) {
    //   throw ArgumentError("Value out of range for Unsigned64.");
    // }
    _value = v;
  }

  // Compute payload
  Uint8List get payload {
    final buffer = ByteData(8);
    final byteList = _value.toUnsigned(64).toByteArray();
    buffer.setUint64(0, _value.toUnsigned(64).toInt(), Endian.big);
    return buffer.buffer.asUint8List();
  }
}

extension BigIntToByteArray on BigInt {
  List<int> toByteArray() {
    final byteList = <int>[];
    BigInt temp = this;
    while (temp > BigInt.zero) {
      byteList.add((temp & BigInt.from(0xff)).toInt());
      temp >>= 8;
    }
    return byteList.reversed.toList();
  }
}

void testCreateUnsignedIntType() {
  // Test Unsigned32
  final a1 = AvpUnsigned32(1); // Code for NAS Port
  a1.value = 294967;
  assert(a1.value == 294967);
  assert(a1.payload.toList().toString() == [0x00, 0x04, 0x80, 0x37].toString());

  // Test Unsigned64 with BigInt
  final a2 = AvpUnsigned64(2); // Code for Framed Interface ID
  a2.value = BigInt.parse("17347878958773879024");
  assert(a2.value == BigInt.parse("17347878958773879024"));
  assert(a2.payload.toList().toString() ==
      [0xf0, 0xc0, 0x0c, 0x00, 0x00, 0x30, 0xc0, 0xf0].toString());

  print('All tests passed!');
}

void main() {
  testCreateUnsignedIntType();
}
