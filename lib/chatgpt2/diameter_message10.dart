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

  // Factory to create from an existing DiameterMessage
  factory DiameterMessage.fromDiameterMessage(DiameterMessage message) {
    return DiameterMessage(
      version: message.version,
      length: message.length,
      flags: message.flags,
      commandCode: message.commandCode,
      applicationId: message.applicationId,
      hopByHopId: message.hopByHopId,
      endToEndId: message.endToEndId,
      avps: message.avps,
    );
  }

  // Factory constructor to create a DiameterMessage from a structured object
  factory DiameterMessage.fromFields(
      {required int version,
      required int length,
      required int flags,
      required int commandCode,
      required int applicationId,
      required int hopByHopId,
      required int endToEndId,
      required List<AVP> apvs}) {
    return DiameterMessage(
        version: version,
        length: length,
        flags: flags,
        commandCode: commandCode,
        applicationId: applicationId,
        hopByHopId: hopByHopId,
        endToEndId: endToEndId,
        avps: apvs);
  }

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

  static Uint8List toBytes({
    required int version,
    required int commandCode,
    required int hopByHopId,
    required int endToEndId,
    required List<Uint8List> avps,
  }) {
    final byteData =
        ByteData(20 + avps.fold(0, (prev, avp) => prev + avp.length));

    // Header encoding (version, length, flags, command code)
    byteData.setInt8(0, version); // Version
    byteData.setInt8(1, byteData.lengthInBytes - 4); // Length
    byteData.setInt8(2, 0); // Flags
    byteData.setInt16(3, commandCode, Endian.big); // Command Code

    byteData.setInt32(4, hopByHopId, Endian.big); // Hop-by-Hop ID
    byteData.setInt32(8, endToEndId, Endian.big); // End-to-End ID

    // Encode AVPs
    int offset = 12;
    for (var avp in avps) {
      byteData.buffer.asUint8List().setRange(offset, offset + avp.length, avp);
      offset += avp.length;
    }

    return byteData.buffer.asUint8List();
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

  // Registry of AVP decoders
  static final Map<int, AVP Function(int, int, int, List<int>)> _avpDecoders = {
    263: (code, flags, length, data) =>
        AVP(code, flags, length, String.fromCharCodes(data)), // Session-Id
    264: (code, flags, length, data) =>
        AVP(code, flags, length, String.fromCharCodes(data)), // Origin-Host
    296: (code, flags, length, data) =>
        AVP(code, flags, length, String.fromCharCodes(data)), // Vendor-Specific
    266: (code, flags, length, data) => AVP(
        code,
        flags,
        length,
        ByteData.sublistView(Uint8List.fromList(data))
            .getUint32(0, Endian.big)), // Vendor-Id
    268: (code, flags, length, data) => AVP(
        code,
        flags,
        length,
        ByteData.sublistView(Uint8List.fromList(data))
            .getUint32(0, Endian.big)), // Result-Code
    257: (code, flags, length, data) => AVP(code, flags, length, data), // Raw
    269: (code, flags, length, data) =>
        AVP(code, flags, length, String.fromCharCodes(data)), // Node-Name

    265: (code, flags, length, data) => AVP(
        code,
        flags,
        length,
        ByteData.sublistView(Uint8List.fromList(data))
            .getUint32(0, Endian.big)), // Vendor-Id

    //       263: (bytes) => String.fromCharCodes(bytes), // Session-Id
    // 264: (bytes) => String.fromCharCodes(bytes), // Origin-Host
    //296: (bytes) => String.fromCharCodes(bytes), // Origin-Realm
    // 266: (bytes) => ByteData.sublistView(bytes).getUint32(0), // Vendor-Id
    278: (code, flags, length, data) => AVP(
        code,
        flags,
        length,
        ByteData.sublistView(Uint8List.fromList(data))
            .getUint32(0)), // Experimental-Result
    //265: (bytes) => ByteData.sublistView(bytes).getUint32(0), // Supported-Vendor-Id
    258: (code, flags, length, data) => AVP(
        code,
        flags,
        length,
        ByteData.sublistView(Uint8List.fromList(data))
            .getUint32(0)), // Auth-Application-Id
  };

  static AVP decode(int code, int flags, int length, List<int> data) {
    // Look up the decoder in the registry
    final decoder = _avpDecoders[code];
    if (decoder != null) {
      return decoder(code, flags, length, data);
    }
    // Default handling for unknown AVP codes
    return AVP(code, flags, length, data);
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

// void main() {
//   final message = DiameterMessage.decode(cert_test);
//   print('Decoded Diameter Message:');
//   print(message);
// }
void main() {
  // Decode the Diameter message
  final decodedMessage = DiameterMessage.decode(cert_test);

  // Print decoded message fields
  print(decodedMessage);

  final dm = DiameterMessage.fromFields(
      version: 1,
      length: 140,
      flags: 128,
      commandCode: 257,
      applicationId: 0,
      hopByHopId: 1470542647,
      endToEndId: 4122139619,
      apvs: [
        AVP(263, 64, 18, 1349348599),
        AVP(264, 96, 27, "gx.pcef.example.com"),
        AVP(296, 64, 24, "pcef.example.com"),
        AVP(266, 96, 12, 10415),
        AVP(278, 64, 12, 219081),
        AVP(265, 96, 12, 10415),
        AVP(258, 64, 12, 4)
      ]);
  //final dm = DiameterMessage.fromDiameterMessage(decodedMessage);

  // Re-encode the decoded message
  final reEncodedMessage = dm.encode();

  // Check if re-encoded message matches the original

  final isMatching = cert_test.length == reEncodedMessage.length &&
      List.generate(cert_test.length,
              (index) => cert_test[index] == reEncodedMessage[index])
          .every((match) => match);

  print('Re-encoded message matches original: $isMatching');
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
