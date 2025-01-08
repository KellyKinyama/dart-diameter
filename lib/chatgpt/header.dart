import 'dart:typed_data';

class DiameterHeader {
  final int version;
  final int commandFlags;
  final int commandCode;
  final int applicationId;
  final int hopByHopId;
  final int endToEndId;

  DiameterHeader({
    required this.version,
    required this.commandFlags,
    required this.commandCode,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
  });

  /// Encode the Diameter header into bytes
  Uint8List encode() {
    final header = ByteData(20);
    header.setUint8(0, version); // Version
    final messageLength = 20; // Placeholder; adjust during message encoding
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

    return header.buffer.asUint8List();
  }

  /// Decode a Diameter header from bytes
  factory DiameterHeader.decode(Uint8List data) {
    if (data.length < 20) {
      throw FormatException('Data too short to decode Diameter header.');
    }

    final header = ByteData.sublistView(data, 0, 20);
    final version = header.getUint8(0);
    final messageLength = ((header.getUint8(1) << 16) |
        (header.getUint8(2) << 8) |
        header.getUint8(3));
    if (data.length < messageLength) {
      throw FormatException('Data length does not match message length.');
    }

    final commandCode = ((header.getUint8(4) << 16) |
        (header.getUint8(5) << 8) |
        header.getUint8(6));
    final commandFlags = header.getUint8(7);
    final applicationId = header.getUint32(8, Endian.big);
    final hopByHopId = header.getUint32(12, Endian.big);
    final endToEndId = header.getUint32(16, Endian.big);

    return DiameterHeader(
      version: version,
      commandFlags: commandFlags,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
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

  // Step 2: Encode the DiameterHeader into bytes
  final encodedHeader = header.encode();
  print("Encoded DiameterHeader: $encodedHeader");

  // Step 3: Decode the DiameterHeader from bytes
  final decodedHeader =
      DiameterHeader.decode(Uint8List.fromList(encodedHeader));
  print("Decoded DiameterHeader:");
  print("  Version: ${decodedHeader.version}");
  print("  Command Flags: ${decodedHeader.commandFlags}");
  print("  Command Code: ${decodedHeader.commandCode}");
  print("  Application ID: ${decodedHeader.applicationId}");
  print("  Hop-by-Hop ID: ${decodedHeader.hopByHopId}");
  print("  End-to-End ID: ${decodedHeader.endToEndId}");
}

// Expected output for the decoded header:
// Decoded DiameterHeader:
//   Version: 1
//   Command Flags: 128
//   Command Code: 257
//   Application ID: 0
//   Hop-by-Hop ID: 12345
//   End-to-End ID: 67890
