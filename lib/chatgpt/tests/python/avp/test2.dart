import 'dart:typed_data';
import 'dart:convert';

class DiameterAVP {
  final int code;
  final int flags;
  final int length;
  final String value;

  DiameterAVP({
    required this.code,
    required this.flags,
    required this.length,
    required this.value,
  });

  // Factory to create AVP from bytes
  factory DiameterAVP.fromBytes(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Data too short to decode Diameter AVP.');
    }

    final code = ByteData.sublistView(data, 0, 4).getUint32(0, Endian.big);
    final flags = data[4];
    final length = ((data[5] << 16) | (data[6] << 8) | data[7]);

    if (data.length < length) {
      throw FormatException(
          'AVP length mismatch. Expected $length, got ${data.length}');
    }

    final valueBytes = data.sublist(8, length);
    final value = utf8.decode(valueBytes.where((b) => b != 0).toList());

    return DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      value: value,
    );
  }

  // Factory to create a copy from another AVP
  factory DiameterAVP.fromAVP(DiameterAVP avp) {
    return DiameterAVP(
      code: avp.code,
      flags: avp.flags,
      length: avp.length,
      value: avp.value,
    );
  }

  bool get isMandatory => (flags & 0x40) != 0;
  bool get isPrivate => (flags & 0x20) != 0;
  bool get isVendor => (flags & 0x80) != 0;

  @override
  String toString() {
    return 'DiameterAVP(code: $code, flags: $flags, length: $length, value: $value)';
  }
}

void testDecodeFromAVP() {
  // Original AVP bytes
  final avpBytes = Uint8List.fromList([
    0x00, 0x00, 0x01, 0xCD, // Code
    0x40, // Flags
    0x00, 0x00, 0x16, // Length
    0x33, 0x32, 0x32, 0x35, // Value: "32251@3gpp.org"
    0x31, 0x40, 0x33, 0x67,
    0x70, 0x70, 0x2E, 0x6F,
    0x72, 0x67, 0x00, 0x00 // Padding
  ]);

  // Create original AVP
  final a1 = DiameterAVP.fromBytes(avpBytes);

  // Create a copy of the AVP
  final a2 = DiameterAVP.fromAVP(a1);

  // Assertions
  assert(a1.code == a2.code, 'Code mismatch');
  assert(a1.isMandatory == a2.isMandatory, 'Mandatory flag mismatch');
  assert(a1.isPrivate == a2.isPrivate, 'Private flag mismatch');
  assert(a1.isVendor == a2.isVendor, 'Vendor flag mismatch');
  assert(a1.length == a2.length, 'Length mismatch');
  assert(a1.value == a2.value, 'Value mismatch');

  print('Test passed: Original and copied AVPs are identical.');
}

void main() {
  testDecodeFromAVP();
}
