import 'dart:typed_data';
import 'dart:convert';

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

class AVP {
  final DiameterAVPHeader header;
  final Uint8List value;

  AVP({
    required this.header,
    required this.value,
  });

  // Encode the AVP (Header + Payload)
  Uint8List encode() {
    final headerBytes = header.encode();
    final payloadBytes = value;
    return Uint8List.fromList(headerBytes + payloadBytes);
  }

  @override
  String toString() {
    return 'AVP{header: ${header.toString()}, value: ${utf8.decode(value)}}';
  }
}

class DiameterAVP {
  final DiameterAVPHeader header;
  final AVP avp;

  DiameterAVP({
    required this.header,
    required this.avp,
  });

  // Encode the full Diameter AVP (Header + Payload)
  Uint8List encode() {
    return avp.encode();
  }

  @override
  String toString() {
    return 'DiameterAVP{header: ${header.toString()}, avp: ${avp.toString()}}';
  }

  // Factory for decoding an AVP from bytes
  static DiameterAVP decode(Uint8List data) {
    final header = DiameterAVPHeader(
      code: ByteData.sublistView(data, 0, 4).getUint32(0, Endian.big),
      flags: DiameterAVPFlags(data[4]),
      length: (data[5] << 16) | (data[6] << 8) | data[7],
      vendorId: 0,
    );
    final value = data.sublist(8, header.length);

    final avp = AVP(
      header: header,
      value: value,
    );

    return DiameterAVP(header: header, avp: avp);
  }
}

void main() {
  final flags = DiameterAVPFlags(0x40); // Mandatory flag
  final header = DiameterAVPHeader(
    code: 1,
    flags: flags,
    length: 16,
    vendorId: 12345,
  );

  final payload = Uint8List.fromList(utf8.encode('Example Payload'));
  final avp = AVP(header: header, value: payload);

  final diameterAVP = DiameterAVP(header: header, avp: avp);

  print(diameterAVP.toString()); // Printing the DiameterAVP (Header + Payload)

  final encodedData = diameterAVP.encode();
  print('Encoded Data: $encodedData');

  // Decoding the data back
  final decodedAVP = DiameterAVP.decode(encodedData);
  print('Decoded AVP: ${decodedAVP.toString()}');
}
