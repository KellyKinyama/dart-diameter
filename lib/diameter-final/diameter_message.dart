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
      //  required int length,
      required int flags,
      required int commandCode,
      required int applicationId,
      required int hopByHopId,
      required int endToEndId,
      required List<AVP> avpList}) {
    // int totalLength = 20; // Base header size: 20 bytes
    int totalLength = 0; // Base header size: 20 bytes
    final buffer = BytesBuilder();

    // Header fields
    buffer.addByte(version); // Version
    totalLength++;

    buffer.add([0, 0, 0]); // Placeholder for length (3 bytes)
    totalLength += 3;

    buffer.addByte(flags); // Flags
    totalLength++;

    buffer.add([
      (commandCode >> 16) & 0xFF,
      (commandCode >> 8) & 0xFF,
      commandCode & 0xFF
    ]);
    totalLength += 3;

    buffer.add([
      (applicationId >> 24) & 0xFF,
      (applicationId >> 16) & 0xFF,
      (applicationId >> 8) & 0xFF,
      applicationId & 0xFF
    ]);
    totalLength += 4;

    buffer.add([
      (hopByHopId >> 24) & 0xFF,
      (hopByHopId >> 16) & 0xFF,
      (hopByHopId >> 8) & 0xFF,
      hopByHopId & 0xFF
    ]);
    totalLength += 4;

    buffer.add([
      (endToEndId >> 24) & 0xFF,
      (endToEndId >> 16) & 0xFF,
      (endToEndId >> 8) & 0xFF,
      endToEndId & 0xFF,
    ]);
    totalLength += 4;

    // Add AVPs
    for (final avp in avpList) {
      final encodedAvp = avp.encode();
      buffer.add(encodedAvp);
      totalLength += encodedAvp.length;
    }

    // Update totalLength in the buffer
    final byteArray = buffer.toBytes();
    byteArray[1] = (totalLength >> 16) & 0xFF;
    byteArray[2] = (totalLength >> 8) & 0xFF;
    byteArray[3] = totalLength & 0xFF;

    return DiameterMessage(
      version: version,
      length: totalLength,
      flags: flags,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avpList,
    );
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
    // 263: (code, flags, length, data) =>
    //     AVP(code, flags, length, String.fromCharCodes(data)), // Session-Id
    // 264: (code, flags, length, data) =>
    //     AVP(code, flags, length, String.fromCharCodes(data)), // Origin-Host
    // 296: (code, flags, length, data) =>
    //     AVP(code, flags, length, String.fromCharCodes(data)), // Vendor-Specific
    // 266: (code, flags, length, data) => AVP(
    //     code,
    //     flags,
    //     length,
    //     ByteData.sublistView(Uint8List.fromList(data))
    //         .getUint32(0, Endian.big)), // Vendor-Id
    // 268: (code, flags, length, data) => AVP(
    //     code,
    //     flags,
    //     length,
    //     ByteData.sublistView(Uint8List.fromList(data))
    //         .getUint32(0, Endian.big)), // Result-Code
    // 257: (code, flags, length, data) => AVP(code, flags, length, data), // Raw
    // 269: (code, flags, length, data) =>
    //     AVP(code, flags, length, String.fromCharCodes(data)), // Node-Name

    // 265: (code, flags, length, data) => AVP(
    //     code,
    //     flags,
    //     length,
    //     ByteData.sublistView(Uint8List.fromList(data))
    //         .getUint32(0, Endian.big)), // Vendor-Id

    // //       263: (bytes) => String.fromCharCodes(bytes), // Session-Id
    // // 264: (bytes) => String.fromCharCodes(bytes), // Origin-Host
    // //296: (bytes) => String.fromCharCodes(bytes), // Origin-Realm
    // // 266: (bytes) => ByteData.sublistView(bytes).getUint32(0), // Vendor-Id
    // 278: (code, flags, length, data) => AVP(
    //     code,
    //     flags,
    //     length,
    //     ByteData.sublistView(Uint8List.fromList(data))
    //         .getUint32(0)), // Experimental-Result
    // //265: (bytes) => ByteData.sublistView(bytes).getUint32(0), // Supported-Vendor-Id
    // 258: (code, flags, length, data) => AVP(
    //     code,
    //     flags,
    //     length,
    //     ByteData.sublistView(Uint8List.fromList(data))
    //         .getUint32(0)), // Auth-Application-Id
  };

  // Registry of AVP decoders
  static final Map<int, AVP Function(int, int, int, List<int>)> _avpEncoders = {
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
    } else if (value is List<dynamic>) {
      // If value is a List<dynamic>, we need to convert it into a List<int>
      final bytes = <int>[];
      for (var item in value) {
        if (item is int) {
          bytes.add(item);
        } else if (item is String) {
          bytes.addAll(item.codeUnits);
        } else {
          throw UnsupportedError("Unsupported AVP value type in List<dynamic>");
        }
      }
      return Uint8List.fromList(bytes);
    }
    {
      throw UnsupportedError(
          "Unsupported AVP value type: ${value.runtimeType}");
    }
  }

  // Encodes the AVP value to bytes
  Uint8List encodeValue() {
    if (value is String) {
      return Uint8List.fromList(value.codeUnits); // String to byte list
    } else if (value is int) {
      final bytes = ByteData(4);
      bytes.setUint32(0, value, Endian.big); // Encode int as 4 bytes
      return bytes.buffer.asUint8List();
    } else if (value is List<int>) {
      return Uint8List.fromList(value); // Raw byte list
    } else if (value is List<dynamic>) {
      // If value is a List<dynamic>, we need to convert it into a List<int>
      final bytes = <int>[];
      for (var item in value) {
        if (item is int) {
          bytes.add(item);
        } else if (item is String) {
          bytes.addAll(item.codeUnits);
        } else {
          throw UnsupportedError("Unsupported AVP value type in List<dynamic>");
        }
      }
      return Uint8List.fromList(bytes);
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
//   // Decode the Diameter message
//   var message = cer_test;
//   var decodedMessage = DiameterMessage.decode(message);

//   // Print decoded message fields
//   print(decodedMessage);

//   var dm = DiameterMessage.fromFields(
//       version: 1,
//       length: 140,
//       flags: 128,
//       commandCode: 257,
//       applicationId: 0,
//       hopByHopId: 1470542647,
//       endToEndId: 4122139619,
//       apvs: [
//         AVP(263, 64, 18, [49, 51, 52, 57, 51, 52, 56, 53, 57, 57]),
//         AVP(264, 96, 27, [
//           103,
//           120,
//           46,
//           112,
//           99,
//           101,
//           102,
//           46,
//           101,
//           120,
//           97,
//           109,
//           112,
//           108,
//           101,
//           46,
//           99,
//           111,
//           109
//         ]),
//         AVP(296, 64, 24, [
//           112,
//           99,
//           101,
//           102,
//           46,
//           101,
//           120,
//           97,
//           109,
//           112,
//           108,
//           101,
//           46,
//           99,
//           111,
//           109
//         ]),
//         AVP(266, 96, 12, [0, 0, 40, 175]),
//         AVP(278, 64, 12, [0, 3, 87, 201]),
//         AVP(265, 96, 12, [0, 0, 40, 175]),
//         AVP(258, 64, 12, [0, 0, 0, 4])
//       ]);
//   //final dm = DiameterMessage.fromDiameterMessage(decodedMessage);

//   // Re-encode the decoded message
//   var reEncodedMessage = dm.encode();

//   // Check if re-encoded message matches the original

//   var isMatching = message.length == reEncodedMessage.length &&
//       List.generate(message.length,
//               (index) => message[index] == reEncodedMessage[index])
//           .every((match) => match);

//   print('Re-encoded message matches original: $isMatching');

//   // Decode the Diameter message
//   message = cea_test;
//   decodedMessage = DiameterMessage.decode(message);

//   // Print decoded message fields
//   print(decodedMessage);

//   dm = DiameterMessage.fromFields(
//       version: 1,
//       length: 160,
//       flags: 0,
//       commandCode: 257,
//       applicationId: 0,
//       hopByHopId: 1470542647,
//       endToEndId: 4122139619,
//       apvs: [
//         AVP(263, 64, 18, [49, 51, 52, 57, 51, 52, 56, 53, 57, 57]),
//         AVP(268, 64, 12, [0, 0, 7, 209]),
//         AVP(264, 96, 16, [116, 101, 115, 116, 46, 99, 111, 109]),
//         AVP(296, 64, 11, [99, 111, 109]),
//         AVP(257, 96, 26,
//             [0, 2, 32, 1, 13, 184, 51, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]),
//         AVP(257, 96, 14, [0, 1, 1, 2, 3, 4]),
//         AVP(266, 96, 12, [0, 0, 0, 123]),
//         AVP(269, 0, 21,
//             [110, 111, 100, 101, 45, 100, 105, 97, 109, 101, 116, 101, 114])
//       ]);
//   //final dm = DiameterMessage.fromDiameterMessage(decodedMessage);

//   // Re-encode the decoded message
//   reEncodedMessage = dm.encode();

//   // Check if re-encoded message matches the original

//   isMatching = message.length == reEncodedMessage.length &&
//       List.generate(message.length,
//               (index) => message[index] == reEncodedMessage[index])
//           .every((match) => match);

//   print('Re-encoded message matches original: $isMatching');
// }

void main() {
  // testDecodeEncodeDiameterMessage();
  // testDecodeCcr();
  testDecodeCcrTestMessage();
}

testDecodeEncodeDiameterMessage() {
  final data = Uint8List.fromList([
    0x01, 0x00, 0x00, 0x34, // version, length
    0x80, 0x00, 0x01, 0x10, // flags, code
    0x00, 0x00, 0x00, 0x04, // application_id
    0x00, 0x00, 0x00, 0x03, // hop_by_hop_id
    0x00, 0x00, 0x00, 0x04, // end_to_end_id
    0x00, 0x00, 0x01, 0x9F, // avp code
    0x40, 0x00, 0x00, 0x0C, // flags, length
    0x00, 0x00, 0x04, 0xB0, // value
    0x00, 0x00, 0x00, 0x1E, // avp code
    0x00, 0x00, 0x00, 0x12, // flags, length
    0x66, 0x6F, 0x6F, 0x62, // value
    0x61, 0x72, 0x31, 0x32, // value
    0x33, 0x34, 0x00, 0x00,
  ]);

  var decodedMessage = DiameterMessage.decode(data);

  // Print decoded message fields
  print(decodedMessage);
}

void testDecodeCcr() {
  final data = Uint8List.fromList([
    0x01,
    0x00,
    0x00,
    0x54,
    0x00,
    0x00,
    0x01,
    0x10,
    0x00,
    0x00,
    0x00,
    0x04,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x40,
    0x00,
    0x00,
    0x0E,
    0x73,
    0x65,
    0x72,
    0x76,
    0x65,
    0x72,
    0x00,
    0x00,
    0x00,
    0x00,
    0x01,
    0x28,
    0x40,
    0x00,
    0x00,
    0x13,
    0x73,
    0x65,
    0x72,
    0x76,
    0x65,
    0x72,
    0x52,
    0x65,
    0x61,
    0x6C,
    0x6D,
    0x00,
    0x00,
    0x00,
    0x01,
    0x0C,
    0x40,
    0x00,
    0x00,
    0x0C,
    0x00,
    0x00,
    0x07,
    0xD1,
    0x00,
    0x00,
    0x01,
    0x07,
    0x40,
    0x00,
    0x00,
    0x0F,
    0x73,
    0x65,
    0x73,
    0x3B,
    0x31,
    0x32,
    0x33,
    0x00,
  ]);

  var decodedMessage = DiameterMessage.decode(data);

  // Print decoded message fields
  print(decodedMessage);
}

void testDecodeCcrTestMessage() {
  var decodedMessage = DiameterMessage.decode(testMessage);

  if (decodedMessage.commandCode != 257) throw "wrong code";
  if (decodedMessage.flags != 0x80) throw "wrong flags";
  if (decodedMessage.version != 0x1) throw "wrong code";
  if (decodedMessage.applicationId != 0) throw "wrong app id";

  // Print decoded message fields
  print(decodedMessage);
  // testMessage is used by the test cases below and also in reflect_test.go.
// The same testMessage is re-created programmatically in TestNewMessage.
//
// Capabilities-Exchange-Request (CER)
// {Code:257,Flags:0x80,Version:0x1,Length:204,ApplicationId:0,HopByHopId:0xa8cc407d,EndToEndId:0xa8c1b2b4}
//   Origin-Host {Code:264,Flags:0x40,Length:12,VendorId:0,Value:DiameterIdentity{test},Padding:0}
//   Origin-Realm {Code:296,Flags:0x40,Length:20,VendorId:0,Value:DiameterIdentity{localhost},Padding:3}
//   Host-IP-Address {Code:257,Flags:0x40,Length:16,VendorId:0,Value:Address{10.1.0.1},Padding:2}
//   Vendor-Id {Code:266,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{13}}
//   Product-Name {Code:269,Flags:0x0,Length:20,VendorId:0,Value:UTF8String{go-diameter},Padding:1}
//   Origin-State-Id {Code:278,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{1397760650}}
//   Supported-Vendor-Id {Code:265,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{10415}}
//   Supported-Vendor-Id {Code:265,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{13}}
//   Auth-Application-Id {Code:258,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{4}}
//   Inband-Security-Id {Code:299,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{0}}
//   Vendor-Specific-Application-Id {Code:260,Flags:0x40,Length:32,VendorId:0,Value:Grouped{
//     Auth-Application-Id {Code:258,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{4}},
//     Vendor-Id {Code:266,Flags:0x40,Length:12,VendorId:0,Value:Unsigned32{10415}},
//   }}
//   Firmware-Revision {Code:267,Flags:0x0,Length:12,VendorId:0,Value:Unsigned32{1}}
}

final testMessage = Uint8List.fromList([
  0x01,
  0x00,
  0x00,
  0xcc,
  0x80,
  0x00,
  0x01,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0xa8,
  0xcc,
  0x40,
  0x7d,
  0xa8,
  0xc1,
  0xb2,
  0xb4,
  0x00,
  0x00,
  0x01,
  0x08,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x74,
  0x65,
  0x73,
  0x74,
  0x00,
  0x00,
  0x01,
  0x28,
  0x40,
  0x00,
  0x00,
  0x11,
  0x6c,
  0x6f,
  0x63,
  0x61,
  0x6c,
  0x68,
  0x6f,
  0x73,
  0x74,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x01,
  0x40,
  0x00,
  0x00,
  0x0e,
  0x00,
  0x01,
  0x0a,
  0x01,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x0a,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x00,
  0x00,
  0x01,
  0x0d,
  0x00,
  0x00,
  0x00,
  0x13,
  0x67,
  0x6f,
  0x2d,
  0x64,
  0x69,
  0x61,
  0x6d,
  0x65,
  0x74,
  0x65,
  0x72,
  0x00,
  0x00,
  0x00,
  0x01,
  0x16,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x53,
  0x50,
  0x22,
  0x8a,
  0x00,
  0x00,
  0x01,
  0x09,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x28,
  0xaf,
  0x00,
  0x00,
  0x01,
  0x09,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x00,
  0x00,
  0x01,
  0x02,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x00,
  0x04,
  0x00,
  0x00,
  0x01,
  0x2b,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x04,
  0x40,
  0x00,
  0x00,
  0x20,
  0x00,
  0x00,
  0x01,
  0x02,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x00,
  0x04,
  0x00,
  0x00,
  0x01,
  0x0a,
  0x40,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x28,
  0xaf,
  0x00,
  0x00,
  0x01,
  0x0b,
  0x00,
  0x00,
  0x00,
  0x0c,
  0x00,
  0x00,
  0x00,
  0x01,
]);

final cer_test = Uint8List.fromList([
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

final cea_test = Uint8List.fromList([
  1,
  0,
  0,
  160,
  0,
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
  12,
  64,
  0,
  0,
  12,
  0,
  0,
  7,
  209,
  0,
  0,
  1,
  8,
  96,
  0,
  0,
  16,
  116,
  101,
  115,
  116,
  46,
  99,
  111,
  109,
  0,
  0,
  1,
  40,
  64,
  0,
  0,
  11,
  99,
  111,
  109,
  0,
  0,
  0,
  1,
  1,
  96,
  0,
  0,
  26,
  0,
  2,
  32,
  1,
  13,
  184,
  51,
  18,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  1,
  1,
  96,
  0,
  0,
  14,
  0,
  1,
  1,
  2,
  3,
  4,
  0,
  0,
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
  0,
  123,
  0,
  0,
  1,
  13,
  0,
  0,
  0,
  21,
  110,
  111,
  100,
  101,
  45,
  100,
  105,
  97,
  109,
  101,
  116,
  101,
  114,
  0,
  0,
  0
]);
