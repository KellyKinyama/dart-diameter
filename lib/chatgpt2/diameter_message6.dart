import 'dart:typed_data';

class DiameterMessage {
  final int version;
  final int length;
  final int flags;
  final int commandCode;
  final int applicationId;
  final int hopByHopId;
  final int endToEndId;
  final List<AVP> avps;

  DiameterMessage({
    required this.version,
    required this.length,
    required this.flags,
    required this.commandCode,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
    required this.avps,
  });

  // Decode Diameter message from raw data
  factory DiameterMessage.decode(Uint8List data) {
    if (data.length < 20) {
      throw FormatException("Invalid Diameter message length");
    }

    final version = data[0];
    final length = (data[1] << 16) | (data[2] << 8) | data[3];
    final flags = data[4];
    final commandCode = (data[5] << 16) | (data[6] << 8) | data[7];
    final applicationId =
        (data[8] << 24) | (data[9] << 16) | (data[10] << 8) | data[11];
    final hopByHopId =
        (data[12] << 24) | (data[13] << 16) | (data[14] << 8) | data[15];
    final endToEndId =
        (data[16] << 24) | (data[17] << 16) | (data[18] << 8) | data[19];

    List<AVP> avps = [];
    int offset = 20;

    while (offset + 8 <= data.length) {
      final avpCode = (data[offset] << 24) |
          (data[offset + 1] << 16) |
          (data[offset + 2] << 8) |
          data[offset + 3];
      final avpFlags = data[offset + 4];
      final avpLength =
          (data[offset + 5] << 16) | (data[offset + 6] << 8) | data[offset + 7];

      if (offset + avpLength > data.length) {
        throw FormatException("Invalid AVP length");
      }

      final avpData = data.sublist(offset + 8, offset + avpLength);

      avps.add(AVP.decode(avpCode, avpFlags, avpLength, avpData));
      offset += avpLength;
      if (avpLength % 4 != 0) {
        offset += 4 - (avpLength % 4); // Padding
      }
    }

    return DiameterMessage(
      version: version,
      length: length,
      flags: flags,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avps,
    );
  }

  Uint8List encode() {
    final buffer = BytesBuilder();
    buffer.add([
      version,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
      flags,
      (commandCode >> 16) & 0xFF,
      (commandCode >> 8) & 0xFF,
      commandCode & 0xFF,
    ]);
    buffer.add([
      (applicationId >> 24) & 0xFF,
      (applicationId >> 16) & 0xFF,
      (applicationId >> 8) & 0xFF,
      applicationId & 0xFF,
      (hopByHopId >> 24) & 0xFF,
      (hopByHopId >> 16) & 0xFF,
      (hopByHopId >> 8) & 0xFF,
      hopByHopId & 0xFF,
      (endToEndId >> 24) & 0xFF,
      (endToEndId >> 16) & 0xFF,
      (endToEndId >> 8) & 0xFF,
      endToEndId & 0xFF,
    ]);
    for (final avp in avps) {
      buffer.add(avp.encode());
    }
    return buffer.toBytes();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Diameter Message:');
    buffer.writeln('  Version: $version');
    buffer.writeln('  Length: $length');
    buffer.writeln('  Flags: $flags');
    buffer.writeln('  Command Code: $commandCode');
    buffer.writeln('  Application ID: $applicationId');
    buffer.writeln('  Hop-by-Hop ID: $hopByHopId');
    buffer.writeln('  End-to-End ID: $endToEndId');
    buffer.writeln('  AVPs:');
    for (final avp in avps) {
      buffer.writeln('    ${avp.toString()}');
    }
    return buffer.toString();
  }
}

class AVP {
  final int code;
  final int flags;
  final int length;
  final dynamic value;

  AVP(this.code, this.flags, this.length, this.value);

  static AVP decode(int code, int flags, int length, List<int> data) {
    switch (code) {
      case 263:
        return AVP(code, flags, length, String.fromCharCodes(data));
      case 264:
      case 296:
      case 269:
        return AVP(code, flags, length, String.fromCharCodes(data));
      case 266:
      case 268:
        return AVP(
            code,
            flags,
            length,
            ByteData.sublistView(Uint8List.fromList(data))
                .getUint32(0, Endian.big));
      case 257:
        return AVP(code, flags, length, data);
      default:
        return AVP(code, flags, length, data);
    }
  }

  Uint8List encode() {
    final dataBytes = _encodeValue();
    final buffer = BytesBuilder();
    buffer.add([
      (code >> 24) & 0xFF,
      (code >> 16) & 0xFF,
      (code >> 8) & 0xFF,
      code & 0xFF,
      flags,
      ((8 + dataBytes.length) >> 16) & 0xFF,
      ((8 + dataBytes.length) >> 8) & 0xFF,
      (8 + dataBytes.length) & 0xFF,
    ]);
    buffer.add(dataBytes);

    // Add padding
    while (buffer.length % 4 != 0) {
      buffer.addByte(0);
    }

    return buffer.toBytes();
  }

  Uint8List _encodeValue() {
    if (value is String) {
      return Uint8List.fromList(value.codeUnits);
    } else if (value is int) {
      final bytes = ByteData(4);
      bytes.setUint32(0, value, Endian.big);
      return bytes.buffer.asUint8List();
    } else if (value is List<int>) {
      return Uint8List.fromList(value);
    } else {
      throw UnsupportedError("Unsupported AVP value type");
    }
  }

  @override
  String toString() {
    return 'AVP(Code: $code, Flags: $flags, Length: $length, Value: $value)';
  }
}

void main() {
  final message = DiameterMessage.decode(cert_test);
  print('Decoded Diameter Message:');
  print(message);
}

final cert_test = Uint8List.fromList([
  1,
  0,
  0,
  140,
  128,
  0,
  1,
  1,
  0,
  0,
  0,
  0,
  87,
  166,
  179,
  55,
  245,
  178,
  219,
  227,
  0,
  0,
  1,
  7,
  64,
  0,
  0,
  18,
  49,
  51,
  52,
  57,
  51,
  52,
  56,
  53,
  57,
  57,
  0,
  0,
  0,
  0,
  1,
  8,
  96,
  0,
  0,
  27,
  103,
  120,
  46,
  112,
  99,
  101,
  102,
  46,
  101,
  120,
  97,
  109,
  112,
  108,
  101,
  46,
  99,
  111,
  109,
  0,
  0,
  0,
  1,
  40,
  64,
  0,
  0,
  24,
  112,
  99,
  101,
  102,
  46,
  101,
  120,
  97,
  109,
  112,
  108,
  101,
  46,
  99,
  111,
  109,
  0,
  0,
  1,
  10,
  96,
  0,
  0,
  12,
  0,
  0,
  40,
  175,
  0,
  0,
  1,
  22,
  64,
  0,
  0,
  12,
  0,
  3,
  87,
  201,
  0,
  0,
  1,
  9,
  96,
  0,
  0,
  12,
  0,
  0,
  40,
  175,
  0,
  0,
  1,
  2,
  64,
  0,
  0,
  12,
  0,
  0,
  0,
  4
]);
