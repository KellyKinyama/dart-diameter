import 'dart:convert';
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

  // Decode the header from a byte list
  static DiameterAVPHeader decode(Uint8List data) {
    final byteData = ByteData.sublistView(data);

    final code = byteData.getInt32(0, Endian.big);
    final flags = DiameterAVPFlags(byteData.getUint8(4));
    final length = (byteData.getUint8(5) << 16) |
        (byteData.getUint8(6) << 8) |
        byteData.getUint8(7);

    int vendorId = 0;
    if (flags.isVendor) {
      vendorId = byteData.getInt32(8, Endian.big);
    }

    return DiameterAVPHeader(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
    );
  }

  static DiameterAVPHeader fromAvpHeader(DiameterAVPHeader avph) {
    // Extract the values from the given DiameterAVPHeader instance
    final code = avph.code;
    final flags = avph.flags;
    final length = avph.length;
    final vendorId = avph.vendorId;

    // Optionally, you can modify or process the header's values here if needed
    // For now, we'll create a new DiameterAVPHeader using the same values

    return DiameterAVPHeader(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
    );
  }

  // Encode the header to a byte list
  Uint8List encode() {
    final byteData = ByteData(8 + (flags.isVendor ? 4 : 0));
    byteData.setInt32(0, code, Endian.big);
    byteData.setUint8(4, flags.flags);
    byteData.setUint8(5, (length >> 16) & 0xFF);
    byteData.setUint8(6, (length >> 8) & 0xFF);
    byteData.setUint8(7, length & 0xFF);

    int offset = 8;
    if (flags.isVendor) {
      byteData.setInt32(offset, vendorId, Endian.big);
      offset += 4;
    }

    return byteData.buffer.asUint8List();
  }

  int getHeaderSize() {
    return 8 + (flags.isVendor ? 4 : 0);
  }

  @override
  String toString() {
    return 'DiameterAVPHeader{code: $code, flags: ${flags.flags}, length: $length, vendorId: $vendorId}';
  }
}

abstract class AVP {
  Uint8List get value;
}

class IntegerAVP extends AVP {
  final int intValue;

  IntegerAVP(this.intValue);

  static IntegerAVP decode(Uint8List data) {
    final value = ByteData.sublistView(data).getInt32(0, Endian.big);
    return IntegerAVP(value);
  }

  @override
  Uint8List get value =>
      (ByteData(4)..setInt32(0, intValue, Endian.big)).buffer.asUint8List();
}

class StringAVP extends AVP {
  final String stringValue;

  StringAVP(this.stringValue);

  static StringAVP decode(Uint8List data) {
    final decodedString = utf8.decode(data);
    return StringAVP(decodedString);
  }

  @override
  Uint8List get value => Uint8List.fromList(utf8.encode(stringValue));
}

class GroupedAVP extends AVP {
  final List<DiameterAVP> avps;

  GroupedAVP(this.avps);

  static GroupedAVP decode(Uint8List data) {
    final avps = <DiameterAVP>[];
    int offset = 0;

    while (offset < data.length) {
      final avp = DiameterAVP.decode(data.sublist(offset));
      avps.add(avp);
      offset += avp.header.length;
    }

    return GroupedAVP(avps);
  }

  @override
  Uint8List get value => Uint8List.fromList(
      avps.expand((avp) => avp.header.encode() + avp.payload.value).toList());
}

class DiameterAVP {
  final DiameterAVPHeader header;
  final AVP payload;

  DiameterAVP({
    required this.header,
    required this.payload,
  });

  static DiameterAVP decode(Uint8List data) {
    final header = DiameterAVPHeader.decode(data);

    final payloadLength = header.length - header.getHeaderSize();

    if (payloadLength < 0 ||
        header.getHeaderSize() + payloadLength > data.length) {
      throw FormatException('Payload length is out of bounds');
    }

    final payloadData = data.sublist(
        header.getHeaderSize(), header.getHeaderSize() + payloadLength);

    AVP payload;
    switch (header.code) {
      case 1:
        payload = IntegerAVP.decode(payloadData);
        break;
      case 461:
        payload = StringAVP.decode(payloadData);
        break;
      case 3:
        payload = GroupedAVP.decode(payloadData);
        break;
      default:
        throw FormatException("Unknown AVP code: ${header.code}");
    }

    return DiameterAVP(
      header: header,
      payload: payload,
    );
  }

  static DiameterAVP fromAvp(DiameterAVP avp) {
    // Extract the header and payload from the given DiameterAVP instance
    final header = avp.header;
    final payload = avp.payload;

    // Optionally, you can modify or process the header and payload here if needed
    // For now, we'll create a new DiameterAVP using the same values

    return DiameterAVP(
      header: header,
      payload: payload,
    );
  }

  Uint8List encode() {
    final headerBytes = header.encode();
    final payloadBytes = payload.value;

    // Calculate padding to ensure total length is a multiple of 4 (after header + payload)
    final totalLength = headerBytes.length + payloadBytes.length;
    final padding = (4 - totalLength % 4) % 4;

    // Create the final byte list with padding
    final paddedPayload = Uint8List(payloadBytes.length + padding);
    paddedPayload.setAll(0, payloadBytes);

    // Adjust the header's length field to reflect the padded size
    final newHeader = DiameterAVPHeader(
      code: header.code,
      flags: header.flags,
      length: totalLength + padding,
      vendorId: header.vendorId,
    );

    final newHeaderBytes = newHeader.encode();

    return Uint8List.fromList(newHeaderBytes + paddedPayload);
  }

  @override
  String toString() {
    return 'DiameterAVP{header: ${header.toString()}, payload: ${payload.toString()}}';
  }
}

void main() {
  final data = <int>[
    0, 0, 0, 1, // AVP Code
    0, 0, 0, 22, // AVP Length
    0, 0, 0, 64, // AVP Flags
    51, 50, 50, 53, 49, 64, 51, 103, 112, 112, 46, 111, 114,
    103, // Example payload (StringAVP)
  ];

  try {
    final avp = DiameterAVP.decode(Uint8List.fromList(data));
    print('Decoded AVP: ${avp.toString()}');
    final encodedAvp = avp.encode();
    print('Encoded AVP (bytes): $encodedAvp');
  } catch (e) {
    print('Error decoding AVP: $e');
  }
}
