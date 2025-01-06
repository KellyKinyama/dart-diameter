import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class DiameterMessage {
  // Header fields
  final int version;
  final int messageLength;
  final int commandFlags;
  final int commandCode;
  final int applicationId;
  final int hopByHopId;
  final int endToEndId;
  final List<DiameterAVP> avps;

  DiameterMessage({
    required this.version,
    required this.messageLength,
    required this.commandFlags,
    required this.commandCode,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
    required this.avps,
  });

  // Encode the message into bytes
  Uint8List encode() {
    final buffer = BytesBuilder();

    // Header
    buffer.addByte(version);
    buffer.add([0, 0]); // Reserved
    buffer.add(_intToBytes(messageLength, 3));
    buffer.add(_intToBytes(commandFlags, 1));
    buffer.add(_intToBytes(commandCode, 3));
    buffer.add(_intToBytes(applicationId, 4));
    buffer.add(_intToBytes(hopByHopId, 4));
    buffer.add(_intToBytes(endToEndId, 4));

    // AVPs
    for (final avp in avps) {
      buffer.add(avp.encode());
    }

    return buffer.toBytes();
  }

  // Decode from bytes
  static DiameterMessage decode(Uint8List data) {
    final reader = ByteData.sublistView(data);
    final version = reader.getUint8(0);
    final messageLength = reader.getUint32(1) & 0xFFFFFF;
    final commandFlags = reader.getUint8(4);
    final commandCode = reader.getUint32(4) & 0xFFFFFF;
    final applicationId = reader.getUint32(8);
    final hopByHopId = reader.getUint32(12);
    final endToEndId = reader.getUint32(16);

    // Parse AVPs
    final avps = <DiameterAVP>[];
    int offset = 20;
    while (offset < messageLength) {
      final avp = DiameterAVP.decode(data.sublist(offset));
      avps.add(avp);
      offset += avp.length;
    }

    return DiameterMessage(
      version: version,
      messageLength: messageLength,
      commandFlags: commandFlags,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avps,
    );
  }

  static Uint8List _intToBytes(int value, int byteCount) {
    final buffer = ByteData(byteCount);
    for (var i = 0; i < byteCount; i++) {
      buffer.setUint8(byteCount - 1 - i, value & 0xFF);
      value >>= 8;
    }
    return buffer.buffer.asUint8List();
  }
}

class DiameterAVP {
  final int code;
  final int flags;
  final int length;
  final Uint8List value;

  DiameterAVP({
    required this.code,
    required this.flags,
    required this.length,
    required this.value,
  });

  Uint8List encode() {
    final buffer = BytesBuilder();
    buffer.add(DiameterMessage._intToBytes(code, 4));
    buffer.addByte(flags);
    buffer.add(DiameterMessage._intToBytes(length, 3));
    buffer.add(value);
    return buffer.toBytes();
  }

  static DiameterAVP decode(Uint8List data) {
    final reader = ByteData.sublistView(data);
    final code = reader.getUint32(0);
    final flags = reader.getUint8(4);
    final length = reader.getUint32(4) & 0xFFFFFF;
    final value = data.sublist(8, length);
    return DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      value: value,
    );
  }
}

Future<void> main() async {
  // Example of constructing a DIAMETER message
  final avp = DiameterAVP(
    code: 1,
    flags: 0,
    length: 12,
    value: Uint8List.fromList(utf8.encode('example')),
  );

  final message = DiameterMessage(
    version: 1,
    messageLength: 20 + avp.length,
    commandFlags: 0,
    commandCode: 272, // Capabilities-Exchange
    applicationId: 0,
    hopByHopId: 12345,
    endToEndId: 67890,
    avps: [avp],
  );

  // Encode the message
  final encoded = message.encode();

  // Simulate sending over a socket
  final server = await ServerSocket.bind('127.0.0.1', 3868);
  server.listen((client) async {
    final data = await client.first;
    final receivedMessage = DiameterMessage.decode(data);
    print('Received message: ${receivedMessage.commandCode}');
    client.close();
  });

  final client = await Socket.connect('127.0.0.1', 3868);
  print('Sending message: $encoded');
  client.add(encoded);
  client.close();
}
