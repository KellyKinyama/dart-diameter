import 'dart:typed_data';
import 'dart:convert';

class DiameterAVPHeader {
  final int code;
  final int flags;
  int length;
  final int vendorId;

  DiameterAVPHeader({
    required this.code,
    required this.flags,
    required this.length,
    required this.vendorId,
  });

  // Method to decode the header from the first part of the byte stream
  static DiameterAVPHeader decodeHeader(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Data too short to decode Diameter AVP header.');
    }

    // AVP Code (4 bytes)
    final code = ByteData.sublistView(data, 0, 4).getUint32(0, Endian.big);

    // Flags (1 byte)
    final flags = data[4];

    // Length (3 bytes)
    final length = ((data[5] << 16) | (data[6] << 8) | data[7]);

    int vendorId = 0;
    int offset = 8; // Start after the mandatory fields
    if ((flags & 0x80) != 0) {
      // Vendor-Specific AVP, Vendor ID is included (4 bytes)
      if (data.length < 12) {
        throw FormatException('Data too short for Vendor-Specific AVP.');
      }
      vendorId = ByteData.sublistView(data, 8, 12).getUint32(0, Endian.big);
      offset += 4; // Skip the vendorId field
    }

    return DiameterAVPHeader(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
    );
  }

  @override
  String toString() {
    return 'DiameterAVPHeader(code: $code, flags: $flags, length: $length, vendorId: $vendorId)';
  }
}

class DiameterAVP {
  final DiameterAVPHeader header;
  Uint8List _value;

  DiameterAVP({
    required this.header,
    required Uint8List value,
  }) : _value = value;

  // Getter for `value`
  Uint8List get value => _value;

  // Setter for `value`
  set value(Uint8List newValue) {
    _value = newValue;
    header.length = _value.length + 8; // Update length accordingly
  }

  /// Encode the Diameter AVP into bytes
  Uint8List encode() {
    final buffer =
        ByteData(8 + _value.length + (header.flags & 0x80 != 0 ? 4 : 0));
    buffer.setUint32(0, header.code, Endian.big);
    buffer.setUint8(4, header.flags);
    buffer.setUint8(5, (header.length >> 16) & 0xFF);
    buffer.setUint8(6, (header.length >> 8) & 0xFF);
    buffer.setUint8(7, header.length & 0xFF);

    int offset = 8;
    if (header.flags & 0x80 != 0) {
      buffer.setUint32(offset, header.vendorId, Endian.big);
      offset += 4;
    }

    buffer.buffer
        .asUint8List()
        .setRange(offset, offset + _value.length, _value);

    // Pad to 4-byte alignment if necessary
    final paddingLength = (4 - (header.length % 4)) % 4;
    return Uint8List.fromList(
      buffer.buffer.asUint8List(0, 8 + _value.length) +
          List<int>.filled(paddingLength, 0),
    );
  }

  /// Decode a Diameter AVP from bytes
  static DiameterAVP decode(Uint8List data) {
    final header = DiameterAVPHeader.decodeHeader(data);

    // Value starts after the header (8 bytes + vendorId if flag is set)
    int valueOffset = 8;
    if ((header.flags & 0x80) != 0) {
      valueOffset += 4; // Skip vendorId if present
    }

    // Extract the value (rest of the data until length, excluding padding)
    final valueLength = header.length - valueOffset;
    if (valueLength < 0 || valueOffset + valueLength > data.length) {
      throw FormatException('Invalid AVP length or value offset.');
    }
    final value = data.sublist(valueOffset, valueOffset + valueLength);

    return DiameterAVP(header: header, value: value);
  }

  @override
  String toString() {
    return 'DiameterAVP(header: $header, value: $_value)';
  }
}

void main() {
  // Example encoding and decoding
  final header = DiameterAVPHeader(
    code: 1,
    flags: 0x80, // Vendor-specific
    length: 16,
    vendorId: 12345,
  );

  final avp = DiameterAVP(
    header: header,
    value: Uint8List.fromList(utf8.encode("Some AVP Value")),
  );

  final encoded = avp.encode();
  print('Encoded AVP: $encoded');

  final decodedAVP = DiameterAVP.decode(encoded);
  print('Decoded AVP: $decodedAVP');
}
