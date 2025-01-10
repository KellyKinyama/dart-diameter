import 'dart:convert';
import 'dart:typed_data';

// DiameterAVPFlags class
class DiameterAVPFlags {
  final int flags;

  DiameterAVPFlags(this.flags);

  bool get isMandatory => (flags & 0x40) != 0;
  bool get isPrivate => (flags & 0x20) != 0;
  bool get isVendor => (flags & 0x80) != 0;

  static DiameterAVPFlags fromAvpFlags({
    required bool isMandatory,
    required bool isPrivate,
    required bool isVendor,
  }) {
    int flags = 0;
    if (isMandatory) flags |= 0x40;
    if (isPrivate) flags |= 0x20;
    if (isVendor) flags |= 0x80;
    return DiameterAVPFlags(flags);
  }
}

// DiameterAVPHeader class
class DiameterAVPHeader {
  final int code;
  final DiameterAVPFlags flags;
  final int length;
  int vendorId;

  DiameterAVPHeader({
    required this.code,
    required this.flags,
    required this.length,
    this.vendorId = 0,
  });

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

  Uint8List encode() {
    final headerLength = 8 + (flags.isVendor ? 4 : 0);
    final byteData = ByteData(headerLength);
    byteData.setInt32(0, code, Endian.big);
    byteData.setUint8(4, flags.flags);
    byteData.setUint8(5, (length >> 16) & 0xFF);
    byteData.setUint8(6, (length >> 8) & 0xFF);
    byteData.setUint8(7, length & 0xFF);
    if (flags.isVendor) {
      byteData.setInt32(8, vendorId, Endian.big);
    }
    return byteData.buffer.asUint8List();
  }

  int getHeaderSize() => 8 + (flags.isVendor ? 4 : 0);

  @override
  String toString() {
    return 'DiameterAVPHeader{code: $code, flags: ${flags.flags}, length: $length, vendorId: $vendorId}';
  }
}

// Base AVP abstract class
abstract class AVP {
  Uint8List get value;
}

// IntegerAVP class
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

// StringAVP class
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

// GroupedAVP class
class GroupedAVP extends AVP {
  final List<DiameterAVP> avps;

  GroupedAVP(this.avps);

  // Decode a GroupedAVP from the provided data
  static GroupedAVP decode(Uint8List data) {
    final avps = <DiameterAVP>[];
    int offset = 0;

    while (offset < data.length) {
      // Ensure enough data remains for at least a header
      if (data.length - offset < 8) {
        throw FormatException('Insufficient data for Diameter AVP header.');
      }

      // Decode the next AVP
      final avp = DiameterAVP.decode(data.sublist(offset));
      avps.add(avp);

      // Advance the offset by the AVP's length
      offset += avp.header.length;

      // Check for padding in the AVP
      final padding = (4 - (avp.header.length % 4)) % 4;
      offset += padding;
    }

    // Validate that the entire data was consumed
    if (offset != data.length) {
      throw FormatException('Extra data found after decoding GroupedAVP.');
    }

    return GroupedAVP(avps);
  }

  // Encode the GroupedAVP into bytes
  @override
  Uint8List get value {
    final encodedAvps = avps.expand((avp) {
      final encoded = avp.header.encode() + avp.payload.value;

      // Calculate padding
      final padding = (4 - (encoded.length % 4)) % 4;
      final paddedBytes = Uint8List(encoded.length + padding);
      paddedBytes.setAll(0, encoded);

      return paddedBytes;
    }).toList();

    return Uint8List.fromList(encodedAvps);
  }
}

// DiameterAVP class
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
    final payload = AVPFactory.create(header.code, payloadData);
    return DiameterAVP(header: header, payload: payload);
  }

  Uint8List encode() {
    final headerBytes = header.encode();
    final payloadBytes = payload.value;
    final padding = calculatePadding(headerBytes.length + payloadBytes.length);
    final paddedPayload = Uint8List(payloadBytes.length + padding);
    paddedPayload.setAll(0, payloadBytes);
    final newHeader = DiameterAVPHeader(
      code: header.code,
      flags: header.flags,
      length: headerBytes.length + paddedPayload.length,
      vendorId: header.vendorId,
    );
    return Uint8List.fromList(newHeader.encode() + paddedPayload);
  }

  static int calculatePadding(int totalLength) => (4 - totalLength % 4) % 4;

  @override
  String toString() {
    return 'DiameterAVP{header: ${header.toString()}, payload: ${payload.toString()}}';
  }
}

// AVPFactory class
class AVPFactory {
  static AVP create(int code, Uint8List data) {
    switch (code) {
      case 1:
        return IntegerAVP.decode(data);
      case 461:
        return StringAVP.decode(data);
      case 3:
        return GroupedAVP.decode(data);
      default:
        throw FormatException("Unknown AVP code: $code");
    }
  }
}

// Main function for testing
void main() {
  final flags = DiameterAVPFlags.fromAvpFlags(
    isMandatory: true,
    isPrivate: false,
    isVendor: false,
  );
  final header = DiameterAVPHeader(
    code: 1,
    flags: flags,
    length: 12,
    vendorId: 0,
  );
  final integerAvp = IntegerAVP(12345);
  final diameterAvp = DiameterAVP(
    header: header,
    payload: integerAvp,
  );
  final encodedAvp = diameterAvp.encode();
  print('Encoded DiameterAVP: $encodedAvp');

  try {
    final decodedAvp = DiameterAVP.decode(encodedAvp);
    print('Decoded DiameterAVP: ${decodedAvp.toString()}');
  } catch (e) {
    print('Error decoding AVP: $e');
  }
}
