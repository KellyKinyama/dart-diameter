import 'dart:typed_data';

import 'diameter_avp.dart';

class DiameterMessage {
  final int version;
  final int commandFlags;
  final int commandCode;
  final int applicationId;
  final int hopByHopId;
  final int endToEndId;
  final List<DiameterAVP> avps;

  DiameterMessage({
    required this.version,
    required this.commandFlags,
    required this.commandCode,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
    required this.avps,
  });

  /// Encode the Diameter message into bytes
  Uint8List encode() {
    final header = ByteData(20);
    header.setUint8(0, version); // Version
    final messageLength =
        20 + avps.fold(0, (sum, avp) => sum + avp.length).toInt();
    header.setUint8(1, (messageLength >> 16) & 0xFF);
    header.setUint8(2, (messageLength >> 8) & 0xFF);
    header.setUint8(3, messageLength & 0xFF);
    header.setUint8(4, (commandCode >> 16) & 0xFF);
    header.setUint8(5, (commandCode >> 8) & 0xFF);
    header.setUint8(6, commandCode & 0xFF);
    header.setUint8(7, commandFlags); // Command Flags
    header.setUint32(8, applicationId, Endian.big);
    header.setUint32(12, hopByHopId, Endian.big);
    header.setUint32(16, endToEndId, Endian.big);

    final avpBytes = avps.expand((avp) => avp.encode()).toList();
    return Uint8List.fromList(header.buffer.asUint8List() + avpBytes);
  }

  /// Decode a Diameter message from bytes
  static DiameterMessage decode(Uint8List data) {
    print("Received: $data");
    if (data.length < 20) {
      throw FormatException('Data too short to decode Diameter message.');
    }

    final header = ByteData.sublistView(data, 0, 20);
    final version = header.getUint8(0);
    final messageLength = ((header.getUint8(1) << 16) |
        (header.getUint8(2) << 8) |
        header.getUint8(3));
    final commandCode = ((header.getUint8(4) << 16) |
        (header.getUint8(5) << 8) |
        header.getUint8(6));
    final commandFlags = header.getUint8(7);
    final applicationId = header.getUint32(8, Endian.big);
    final hopByHopId = header.getUint32(12, Endian.big);
    final endToEndId = header.getUint32(16, Endian.big);

    final avps = <DiameterAVP>[];
    int offset = 20;
    while (offset < messageLength) {
      final avp = DiameterAVP.decode(data.sublist(offset));
      avps.add(avp);
      offset += avp.length;
    }

    return DiameterMessage(
      version: version,
      commandFlags: commandFlags,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avps,
    );
  }
}
