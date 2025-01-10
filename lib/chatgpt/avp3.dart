import 'dart:typed_data';

class DiameterAVPFlags {
  final int flags;

  DiameterAVPFlags(this.flags);

  bool get isMandatory => (flags & 0x40) != 0;
  bool get isPrivate => (flags & 0x20) != 0;
  bool get isVendor => (flags & 0x80) != 0;
}

class DiameterAVPHeader {
  final int code;
  final DiameterAVPFlags flags;
  final int length;
  final int vendorId;

  DiameterAVPHeader({
    required this.code,
    required this.flags,
    required this.length,
    required this.vendorId,
  });

  // Encode the header into bytes
  Uint8List encode() {
    final buffer = ByteData(8 + (flags.isVendor ? 4 : 0));
    buffer.setUint32(0, code, Endian.big);
    buffer.setUint8(4, flags.flags);
    buffer.setUint8(5, (length >> 16) & 0xFF);
    buffer.setUint8(6, (length >> 8) & 0xFF);
    buffer.setUint8(7, length & 0xFF);

    int offset = 8;
    if (flags.isVendor) {
      buffer.setUint32(offset, vendorId, Endian.big);
      offset += 4;
    }

    return buffer.buffer.asUint8List();
  }

  @override
  String toString() {
    return 'DiameterAVPHeader{'
        'code: $code, '
        'flags: ${flags.flags}, '
        'isMandatory: ${flags.isMandatory}, '
        'isPrivate: ${flags.isPrivate}, '
        'isVendor: ${flags.isVendor}, '
        'length: $length, '
        'vendorId: $vendorId}';
  }
}

class DiameterAVP {
  final DiameterAVPHeader header;
  final Uint8List payload;

  DiameterAVP({
    required this.header,
    required this.payload,
  });

  // Encode the entire AVP
  Uint8List encode() {
    final headerBytes = header.encode();
    final paddingLength = (4 - ((header.length + payload.length) % 4)) % 4;
    return Uint8List.fromList(
      headerBytes + payload + List<int>.filled(paddingLength, 0),
    );
  }

  // Decode the AVP from bytes
  static DiameterAVP decode(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Data too short to decode Diameter AVP.');
    }

    // Decode the AVP header
    final code = ByteData.sublistView(data, 0, 4).getUint32(0, Endian.big);
    final flags = DiameterAVPFlags(data[4]);
    final length = ((data[5] << 16) | (data[6] << 8) | data[7]);

    if (length > data.length) {
      throw FormatException('AVP length mismatch.');
    }

    int vendorId = 0;
    int valueOffset = 8;
    if (flags.isVendor) {
      vendorId = ByteData.sublistView(data, 8, 12).getUint32(0, Endian.big);
      valueOffset += 4;
    }

    final payload =
        data.sublist(valueOffset, valueOffset + length - valueOffset);

    final header = DiameterAVPHeader(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
    );

    return DiameterAVP(header: header, payload: payload);
  }

  @override
  String toString() {
    return 'DiameterAVP{header: $header, payload: ${payload.length} bytes}';
  }
}

void main() {
  // Example usage
  final header = DiameterAVPHeader(
    code: 1,
    flags: DiameterAVPFlags(0x40), // Mandatory
    length: 16,
    vendorId: 12345,
  );
  final avp = DiameterAVP(
    header: header,
    payload: Uint8List.fromList([1, 2, 3, 4]),
  );

  final encoded = avp.encode();
  print('Encoded AVP: $encoded');

  final decoded = DiameterAVP.decode(encoded);
  print('Decoded AVP: $decoded');
}
