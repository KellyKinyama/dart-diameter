import 'dart:typed_data';
import 'dart:convert';

/// Extended Diameter AVP Class
class DiameterAVP {
  final int code;
  final int flags;
  final Uint8List value;
  final int vendorId; // Optional vendor-specific AVPs

  DiameterAVP({
    required this.code,
    required this.flags,
    required this.value,
    this.vendorId = 0,
  });

  /// Calculate the length of the AVP
  int get length => 8 + value.length + (flags & 0x80 != 0 ? 4 : 0);

  /// Encode the AVP into bytes
  Uint8List encode() {
    final header = ByteData(8 + (flags & 0x80 != 0 ? 4 : 0));
    header.setUint32(0, code, Endian.big);
    header.setUint8(4, flags);

    final totalLength = length;
    header.setUint8(5, (totalLength >> 16) & 0xFF);
    header.setUint8(6, (totalLength >> 8) & 0xFF);
    header.setUint8(7, totalLength & 0xFF);

    if (flags & 0x80 != 0) {
      header.setUint32(8, vendorId, Endian.big);
    }

    return Uint8List.fromList(header.buffer.asUint8List() + value);
  }

  /// Decode an AVP from bytes
  static DiameterAVP decode(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Data too short to decode Diameter AVP.');
    }

    final header = ByteData.sublistView(data, 0, 8);
    final code = header.getUint32(0, Endian.big);
    final flags = header.getUint8(4);
    final length = ((header.getUint8(5) << 16) |
        (header.getUint8(6) << 8) |
        header.getUint8(7));

    if (length > data.length) {
      throw FormatException('AVP length exceeds available data.');
    }

    int offset = 8;
    int vendorId = 0;

    if (flags & 0x80 != 0) {
      vendorId = ByteData.sublistView(data, 8, 12).getUint32(0, Endian.big);
      offset += 4;
    }

    final value = Uint8List.sublistView(data, offset, length);
    return DiameterAVP(
        code: code, flags: flags, value: value, vendorId: vendorId);
  }

  /// Convenience method to encode string values
  static DiameterAVP stringAVP(int code, String value,
      {int flags = 0, int vendorId = 0}) {
    return DiameterAVP(
      code: code,
      flags: flags,
      value: Uint8List.fromList(utf8.encode(value)),
      vendorId: vendorId,
    );
  }

  /// Convenience method to encode integer values
  static DiameterAVP integerAVP(int code, int value,
      {int flags = 0, int vendorId = 0}) {
    final valueBytes = ByteData(4)..setUint32(0, value, Endian.big);
    return DiameterAVP(
      code: code,
      flags: flags,
      value: valueBytes.buffer.asUint8List(),
      vendorId: vendorId,
    );
  }

  /// Convenience method to encode grouped AVPs
  static DiameterAVP groupedAVP(int code, List<DiameterAVP> avps,
      {int flags = 0, int vendorId = 0}) {
    final valueBytes = avps.expand((avp) => avp.encode()).toList();
    return DiameterAVP(
      code: code,
      flags: flags,
      value: Uint8List.fromList(valueBytes),
      vendorId: vendorId,
    );
  }
}

final hostIdentityAVP = DiameterAVP.stringAVP(
  264, // Host-Identity AVP Code
  'MyDiameterHost',
);
//Integer AVP

final vendorIdAVP = DiameterAVP.integerAVP(
  266, // Vendor-Id AVP Code
  10415, // Example vendor ID
);
//Grouped AVP
final groupedAVP = DiameterAVP.groupedAVP(
  456, // Example Grouped AVP Code
  [
    DiameterAVP.stringAVP(264, 'GroupedHostIdentity'),
    DiameterAVP.integerAVP(266, 10415),
  ],
);
