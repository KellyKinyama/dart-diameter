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

  static DiameterAVP fromBytes(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Data too short to decode Diameter AVP.');
    }

    // AVP Code (4 bytes)
    final code = ByteData.sublistView(data, 0, 4).getUint32(0, Endian.big);

    // Flags (1 byte)
    final flags = data[4];

    // Length (3 bytes)
    final length = ((data[5] << 16) | (data[6] << 8) | data[7]);

    if (data.length < length) {
      throw FormatException(
          'AVP length mismatch. Expected $length, got ${data.length}');
    }

    // Value (starts at offset 8 and goes until `length`)
    final valueBytes = data.sublist(8, length);
    final value = utf8.decode(valueBytes.where((b) => b != 0).toList());

    return DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      value: value,
    );
  }

  Uint8List encode() {
    // Convert value to bytes and calculate the total length
    final valueBytes = utf8.encode(value);
    final totalLength = 8 + valueBytes.length;

    // Create a ByteData buffer
    final buffer = ByteData(totalLength);

    // Write AVP Code (4 bytes)
    buffer.setUint32(0, code, Endian.big);

    // Write Flags (1 byte)
    buffer.setUint8(4, flags);

    // Write Length (3 bytes)
    buffer.setUint8(5, (totalLength >> 16) & 0xFF);
    buffer.setUint8(6, (totalLength >> 8) & 0xFF);
    buffer.setUint8(7, totalLength & 0xFF);

    // Write Value (remaining bytes)
    for (int i = 0; i < valueBytes.length; i++) {
      buffer.setUint8(8 + i, valueBytes[i]);
    }

    // Add padding if needed to ensure 4-byte alignment
    final paddingLength = (4 - (totalLength % 4)) % 4;
    final paddedData = buffer.buffer.asUint8List();
    return Uint8List.fromList(paddedData + List.filled(paddingLength, 0));
  }

  bool get isMandatory => (flags & 0x40) != 0;
  bool get isPrivate => (flags & 0x20) != 0;
  bool get isVendor => (flags & 0x80) != 0;

  @override
  String toString() {
    return 'DiameterAVP(code: $code, flags: $flags, length: $length, value: $value)';
  }
}

void testDecodeFromBytes() {
  // Create an AVP from network-received bytes
  final avpBytes = Uint8List.fromList([
    0x00,
    0x00,
    0x01,
    0xcd,
    0x40,
    0x00,
    0x00,
    0x16,
    0x33,
    0x32,
    0x32,
    0x35,
    0x31,
    0x40,
    0x33,
    0x67,
    0x70,
    0x70,
    0x2e,
    0x6f,
    0x72,
    0x67,
    0x00,
    0x00
  ]);

  final avp = DiameterAVP.fromBytes(avpBytes);

  assert(avp.code == 461);
  assert(avp.isMandatory == true);
  assert(avp.isPrivate == false);
  assert(avp.isVendor == false);
  assert(avp.length == 22);
  assert(avp.value == '32251@3gpp.org');

  print("AVP decoded successfully: $avp");
}

// void main() {
//   testDecodeFromBytes();
// }

void main() {
  testDecodeFromBytes();
  // Create a DiameterAVP instance
  final avp = DiameterAVP(
    code: 461,
    flags: 0x40, // Mandatory flag set
    length: 22,
    value: "32251@3gpp.org",
  );

  // Encode the AVP into a Uint8List
  final encodedData = avp.encode();

  print("Encoded AVP: ${encodedData.toList()}");

  // Decode the AVP back to verify
  final decodedAVP = DiameterAVP.fromBytes(encodedData);

  print("Decoded AVP: $decodedAVP");
}
