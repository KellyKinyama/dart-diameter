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
    int offset = 20; // Start after header

    // Decode AVPs
    while (offset + 8 <= data.length) {
      final avpCode = (data[offset] << 24) |
          (data[offset + 1] << 16) |
          (data[offset + 2] << 8) |
          data[offset + 3];
      final avpFlags = data[offset + 4];
      final avpLength =
          (data[offset + 5] << 16) | (data[offset + 6] << 8) | data[offset + 7];

      // Handle padding: Calculate padding based on AVP length
      int padding = 0;
      if (avpLength % 4 != 0) {
        padding =
            4 - (avpLength % 4); // Padding needed to align to 4-byte boundary
      }

      final avpData = data.sublist(
          offset + 8, offset + avpLength); // Extract the actual AVP data
      avps.add(AVP(avpCode, avpFlags, avpLength, avpData));

      offset += avpLength +
          padding; // Move the offset to the next AVP, accounting for padding
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

  // Encode Diameter message to raw data
  Uint8List encode() {
    // Calculate total length
    final totalLength =
        20 + avps.fold<int>(0, (sum, avp) => sum + avp.totalLength);

    final buffer = ByteData(totalLength);

    // Header
    buffer.setUint8(0, version);
    buffer.setUint8(1, (totalLength >> 16) & 0xFF);
    buffer.setUint8(2, (totalLength >> 8) & 0xFF);
    buffer.setUint8(3, totalLength & 0xFF);
    buffer.setUint8(4, flags);
    buffer.setUint8(5, (commandCode >> 16) & 0xFF);
    buffer.setUint8(6, (commandCode >> 8) & 0xFF);
    buffer.setUint8(7, commandCode & 0xFF);
    buffer.setUint32(8, applicationId, Endian.big);
    buffer.setUint32(12, hopByHopId, Endian.big);
    buffer.setUint32(16, endToEndId, Endian.big);

    // AVPs
    int offset = 20;
    for (final avp in avps) {
      final avpBytes = avp.encode();
      buffer.buffer
          .asUint8List()
          .setRange(offset, offset + avp.totalLength, avpBytes);
      offset += avp.totalLength;
    }

    return buffer.buffer.asUint8List();
  }
}

class AVP {
  final int avpCode;
  final int flags;
  final int length;
  final List<int> data;

  AVP(this.avpCode, this.flags, this.length, this.data);

  int get totalLength {
    final padding = (length % 4 == 0) ? 0 : 4 - (length % 4);
    return length + padding;
  }

  Uint8List encode() {
    final buffer = ByteData(totalLength);

    buffer.setUint32(0, avpCode, Endian.big);
    buffer.setUint8(4, flags);
    buffer.setUint8(5, (length >> 16) & 0xFF);
    buffer.setUint8(6, (length >> 8) & 0xFF);
    buffer.setUint8(7, length & 0xFF);

    buffer.buffer.asUint8List().setRange(8, 8 + data.length, data);

    // Add padding
    final padding = (length % 4 == 0) ? 0 : 4 - (length % 4);
    if (padding > 0) {
      buffer.buffer.asUint8List().fillRange(8 + data.length, totalLength, 0);
    }

    return buffer.buffer.asUint8List();
  }

  @override
  String toString() {
    return 'AVP Code: $avpCode, Flags: $flags, Length: $length, Data: $data';
  }
}

void main() {
  // Decode Diameter message
  try {
    final message = DiameterMessage.decode(cea_test);

    // Print decoded message
    print('Decoded Diameter Message:');
    print('Version: ${message.version}');
    print('Length: ${message.length}');
    print('Flags: ${message.flags}');
    print('Command Code: ${message.commandCode}');
    print('Application ID: ${message.applicationId}');
    print('Hop-by-Hop ID: ${message.hopByHopId}');
    print('End-to-End ID: ${message.endToEndId}');

    print('AVPs:');
    for (final avp in message.avps) {
      print(avp);
    }

    // Encode message back to bytes
    final encodedData = message.encode();
    print('\nEncoded Diameter Message:  $encodedData');
    print('\nExpected Diameter Message: $cert_test');
  } catch (e) {
    print('Error: $e');
  }
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
