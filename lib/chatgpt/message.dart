import 'dart:convert';
import 'dart:typed_data';

import 'avp.dart';
import 'header.dart';

class DiameterMessage {
  final DiameterHeader header;
  final List<DiameterAVP> avps;

  DiameterMessage({
    required this.header,
    required this.avps,
  });

  /// Encode the Diameter message into bytes
  Uint8List encode() {
    // Encode the header
    final headerBytes = header.encode();

    // Encode the AVPs
    final avpBytes = avps.expand((avp) => avp.encode()).toList();

    // Adjust the message length in the header (header + AVPs)
    final totalLength = headerBytes.length + avpBytes.length;
    headerBytes[1] = (totalLength >> 16) & 0xFF;
    headerBytes[2] = (totalLength >> 8) & 0xFF;
    headerBytes[3] = totalLength & 0xFF;

    // Combine the header and AVPs into a single byte array
    return Uint8List.fromList(headerBytes + avpBytes);
  }

  /// Decode a Diameter message from bytes
  factory DiameterMessage.decode(Uint8List data) {
    if (data.length < 20) {
      throw FormatException('Data too short to decode Diameter message.');
    }

    // Decode the header
    final header = DiameterHeader.decode(data);

    // Decode the AVPs
    final avps = <DiameterAVP>[];
    int offset = 20; // AVPs start after the 20-byte header
    while (offset < data.length) {
      final avp = DiameterAVP.decode(data.sublist(offset));
      avps.add(avp);
      offset += avp.length;
    }

    return DiameterMessage(
      header: header,
      avps: avps,
    );
  }
}

void main() {
  // Step 1: Create a DiameterHeader
  final header = DiameterHeader(
    version: 1,
    commandFlags: 0x80, // Request flag set
    commandCode: 257, // Capability-Exchange-Request
    applicationId: 0, // Default application
    hopByHopId: 12345,
    endToEndId: 67890,
  );

  // Step 2: Create DiameterAVPs
  final avp1 = DiameterAVP.stringAVP(1, "Example String AVP");
  final avp2 = DiameterAVP.integerAVP(2, 42);
  final groupedAvp = DiameterAVP.groupedAVP(3, [avp1, avp2]);

  // Step 3: Create a DiameterMessage
  final message = DiameterMessage(
    header: header,
    avps: [avp1, avp2, groupedAvp],
  );

  // Step 4: Encode the DiameterMessage into bytes
  final encodedMessage = message.encode();
  print("Encoded DiameterMessage: $encodedMessage");

  // Step 5: Decode the DiameterMessage from bytes
  final decodedMessage = DiameterMessage.decode(encodedMessage);
  print("Decoded DiameterMessage:");
  print("Version: ${decodedMessage.header.version}");
  print("Command Code: ${decodedMessage.header.commandCode}");
  print("Application ID: ${decodedMessage.header.applicationId}");
  print("AVP Count: ${decodedMessage.avps.length}");

  // Step 6: Inspect the AVPs in the decoded message
  for (int i = 0; i < decodedMessage.avps.length; i++) {
    final avp = decodedMessage.avps[i];
    print("AVP $i:");
    print("  Code: ${avp.code}");
    print("  Flags: ${avp.flags}");
    print("  Value Length: ${avp.value.length}");
    if (avp.code == 1) {
      // Decode string value
      print("  Value (String): ${utf8.decode(avp.value)}");
    } else if (avp.code == 2) {
      // Decode integer value
      final intValue = ByteData.sublistView(avp.value).getUint32(0, Endian.big);
      print("  Value (Integer): $intValue");
    } else if (avp.code == 3) {
      print("  Value: Grouped AVP");
    }
  }
}
