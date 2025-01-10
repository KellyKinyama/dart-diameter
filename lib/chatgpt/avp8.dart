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

    // Extract header values
    final code = byteData.getInt32(0, Endian.big);
    final flags = DiameterAVPFlags(byteData.getUint8(4));
    final length = (byteData.getUint8(5) << 16) |
        (byteData.getUint8(6) << 8) |
        byteData.getUint8(7);

    // If the 'isVendor' flag is set, decode the vendorId
    int vendorId = 0;
    if (flags.isVendor) {
      vendorId = byteData.getInt32(8, Endian.big);
    }

    print(
        'Decoded Header: Code: $code, Length: $length, Flags: $flags, Vendor ID: $vendorId');

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
    }

    return byteData.buffer.asUint8List();
  }

  int getHeaderSize() {
    return 8 +
        (flags.isVendor
            ? 4
            : 0); // The header size includes vendorId if necessary
  }

  @override
  String toString() {
    return 'DiameterAVPHeader{code: $code, flags: ${flags.flags}, length: $length, vendorId: $vendorId}';
  }
}

abstract class AVP {
  Uint8List get value; // Getter should return Uint8List for all derived classes
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

  @override
  String toString() {
    return 'StringAVP{value: "$stringValue"}'; // Print the string value
  }
}

class GroupedAVP extends AVP {
  final List<DiameterAVP> avps;

  GroupedAVP(this.avps);

  static GroupedAVP decode(Uint8List data) {
    final avps = <DiameterAVP>[];
    int offset = 0;

    // Decoding logic for grouped AVPs
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

  // Factory method to create an AVP based on the code
  static DiameterAVP decode(Uint8List data) {
    // Decode the AVP header first
    final header = DiameterAVPHeader.decode(data);

    // Get the payload length from the header
    final payloadLength = header.length - header.getHeaderSize();

    // Ensure that the payload data doesn't exceed the available range
    if (payloadLength < 0 ||
        header.getHeaderSize() + payloadLength > data.length) {
      throw FormatException('Payload length is out of bounds');
    }

    // Extract the payload from the data
    final payloadData = data.sublist(
        header.getHeaderSize(), header.getHeaderSize() + payloadLength);

    // Based on the AVP code, determine the payload type
    AVP payload;
    switch (header.code) {
      case 1: // Example code for IntegerAVP
        payload = IntegerAVP.decode(payloadData);
        break;
      case 461: // Example code for StringAVP
        payload = StringAVP.decode(payloadData);
        break;
      case 3: // Example code for GroupedAVP
        payload = GroupedAVP.decode(payloadData);
        break;
      // Add other cases as needed for different AVP types
      default:
        throw FormatException("Unknown AVP code: ${header.code}");
    }

    return DiameterAVP(
      header: header,
      payload: payload,
    );
  }

  Uint8List encode() {
    final headerBytes = header.encode();
    return Uint8List.fromList(headerBytes + payload.value);
  }

  @override
  String toString() {
    return 'DiameterAVP{header: ${header.toString()}, payload: ${payload.toString()}}';
  }
}

void main() {
  final data = <int>[
    0, 0, 0, 1, // AVP Code
    0, 0, 0, 12, // AVP Length
    0, 0, 0, 64, // AVP Flags
    0, 0, 0, 0, // Example payload (IntegerAVP)
  ];

  try {
    final avp = DiameterAVP.decode(Uint8List.fromList(data));
    print('Decoded AVP: ${avp.toString()}');
  } catch (e) {
    print('Error decoding AVP: $e');
  }
}
