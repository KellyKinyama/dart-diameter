import 'dart:typed_data';
import './diameter_message.dart';

class CapabilitiesExchangeRequest extends DiameterMessage {
  static const int COMMAND_CODE = 257;

  CapabilitiesExchangeRequest({
    required int version,
    required int length,
    required int flags,
    required int commandCode,
    required int applicationId,
    required int hopByHopId,
    required int endToEndId,
    required List<AVP> avps,
  }) : super(
          version: version,
          length: length, // Initially 0, to be calculated later
          flags: flags,
          commandCode: COMMAND_CODE,
          applicationId: applicationId,
          hopByHopId: hopByHopId,
          endToEndId: endToEndId,
          avps: avps,
        );

  factory CapabilitiesExchangeRequest.decode(Uint8List data) {
    final message = DiameterMessage.decode(data);

    if (message.commandCode != COMMAND_CODE) {
      throw FormatException("Invalid Command Code for CER");
    }

    return CapabilitiesExchangeRequest(
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

  @override
  Uint8List encode() {
    // Encode AVPs and calculate their lengths
    // final encodedAVPs = avps.map((avp) => avp.encode()).toList();

    // Calculate total length: Header (20 bytes) + sum of all AVP lengths
    // final int totalLength =
    //     20 + encodedAVPs.fold(0, (prev, avp) => prev + avp.length);

    // Update the length field in the header
    // this.length = totalLength;

    // Now, encode the complete message
    // return DiameterMessage.toBytes(
    //   version: version,
    //   commandCode: COMMAND_CODE,
    //   hopByHopId: hopByHopId,
    //   endToEndId: endToEndId,
    //   avps: encodedAVPs,
    // );

    return super.encode();
  }

  // Create a sample CER message
  // static CapabilitiesExchangeRequest createSample(
  //   int version,
  //   int hopByHopId,
  //   int endToEndId,
  // ) {
  //   // Define AVPs for the CER message (ensure proper byte array lengths)
  //   final avps = <AVP>[
  //     AVP(263, 64, 18, [51, 52, 52, 51, 49, 51, 51, 50, 50, 48]), // Session-Id
  //     AVP(264, 96, 19,
  //         [103, 120, 46, 112, 99, 101, 102, 46, 99, 111, 109]), // Origin-Host
  //     AVP(296, 64, 16, [112, 99, 101, 102, 46, 99, 111, 109]), // Origin-Realm
  //     AVP(266, 96, 12, [0, 0, 40, 175]), // Vendor-ID
  //     AVP(278, 64, 12, [0, 3, 87, 201]), // Product-Name
  //     AVP(265, 96, 12, [0, 0, 40, 175]), // Vendor-ID again
  //     AVP(258, 64, 12, [0, 0, 0, 4]) // Supported-Features
  //   ];

  //   return CapabilitiesExchangeRequest(
  //     version: version,
  //     flags: 128, // Assume 128 (Request flag) for this example
  //     applicationId: 0,
  //     hopByHopId: hopByHopId,
  //     endToEndId: endToEndId,
  //     avps: avps,
  //   );
  // }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Capabilities Exchange Request (CER):');
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

// void main() {
//   final cer = CapabilitiesExchangeRequest.createSample(1, 12345, 67890);
//   print(cer);
//   final encoded = cer.encode();
//   print('Encoded CER Message: $encoded');
//   print("Decoded again: ${DiameterMessage.decode(encoded)}");
// }

void main() {
  // CapabilitiesExchangeRequest(
  //     version: 1,
  //     length: 140,
  //     flags: 128,
  //     commandCode: 257,
  //     applicationId: 0,
  //     hopByHopId: 1470542647,
  //     endToEndId: 4122139619,
  //     avps: [
  //       AVP(263, 64, 18, [51, 52, 52, 51, 49, 51, 51, 50, 50, 48]),
  //       AVP(264, 96, 19, [103, 120, 46, 112, 99, 101, 102, 46, 99, 111, 109]),
  //       AVP(296, 64, 16, [112, 99, 101, 102, 46, 99, 111, 109]),
  //       AVP(266, 96, 12, [0, 0, 40, 175]),
  //       AVP(278, 64, 12, [0, 3, 87, 201]),
  //       AVP(265, 96, 12, [0, 0, 40, 175]),
  //       AVP(258, 64, 12, [0, 0, 0, 4])
  //     ]);
  // Version: 1
  // Length: 140
  // Flags: 128
  // Command Code: 257
  // Application ID: 0
  // Hop-by-Hop ID: 1470542647
  // End-to-End ID: 4122139619
  // AVPs:
  //   AVP(Code: 263, Flags: 64, Length: 18, Value: 1349348599)
  //   AVP(Code: 264, Flags: 96, Length: 27, Value: gx.pcef.example.com)
  //   AVP(Code: 296, Flags: 64, Length: 24, Value: pcef.example.com)
  //   AVP(Code: 266, Flags: 96, Length: 12, Value: 10415)
  //   AVP(Code: 278, Flags: 64, Length: 12, Value: 219081)
  //   AVP(Code: 265, Flags: 96, Length: 12, Value: 10415)
  //   AVP(Code: 258, Flags: 64, Length: 12, Value: 4)

  final cer = DiameterMessage(
      version: 1,
      length: 140,
      flags: 128,
      commandCode: 257,
      applicationId: 0,
      hopByHopId: 1470542647,
      endToEndId: 4122139619,
      avps: [
        AVP(263, 64, 18, [51, 52, 52, 51, 49, 51, 51, 50, 50, 48]),
        AVP(264, 96, 19, [103, 120, 46, 112, 99, 101, 102, 46, 99, 111, 109]),
        AVP(296, 64, 16, [112, 99, 101, 102, 46, 99, 111, 109]),
        AVP(266, 96, 12, [0, 0, 40, 175]),
        AVP(278, 64, 12, [0, 3, 87, 201]),
        AVP(265, 96, 12, [0, 0, 40, 175]),
        AVP(258, 64, 12, [0, 0, 0, 4])
      ]);

  final cerFields = DiameterMessage.fromFields(
      version: 1,
      // length: 140,
      flags: 128,
      commandCode: 257,
      applicationId: 0,
      hopByHopId: 1470542647,
      endToEndId: 4122139619,
      avpList: [
        AVP(263, 64, 18, [51, 52, 52, 51, 49, 51, 51, 50, 50, 48]),
        AVP(264, 96, 19, [103, 120, 46, 112, 99, 101, 102, 46, 99, 111, 109]),
        AVP(296, 64, 16, [112, 99, 101, 102, 46, 99, 111, 109]),
        AVP(266, 96, 12, [0, 0, 40, 175]),
        AVP(278, 64, 12, [0, 3, 87, 201]),
        AVP(265, 96, 12, [0, 0, 40, 175]),
        AVP(258, 64, 12, [0, 0, 0, 4])
      ]);

  print("message length: ${cerFields.length}");
  print("message length: ${cer.length}");

  // final encoded = cerFields.encode();
  // print('Encoded CER Message: $encoded');
  // print("Decoded again: ${DiameterMessage.decode(encoded)}");
}

//  Version: 1
//   Length: 124
//   Flags: 128
//   Command Code: 257
//   Application ID: 0
//   Hop-by-Hop ID: 57937898
//   End-to-End ID: 2255810703
//   AVPs:
//     AVP(Code: 263, Flags: 64, Length: 18, Value: [51, 52, 52, 51, 49, 51, 51, 50, 50, 48])
//     AVP(Code: 264, Flags: 96, Length: 19, Value: [103, 120, 46, 112, 99, 101, 102, 46, 99, 111, 109])
//     AVP(Code: 296, Flags: 64, Length: 16, Value: [112, 99, 101, 102, 46, 99, 111, 109])
//     AVP(Code: 266, Flags: 96, Length: 12, Value: [0, 0, 40, 175])
//     AVP(Code: 278, Flags: 64, Length: 12, Value: [0, 3, 87, 201])
//     AVP(Code: 265, Flags: 96, Length: 12, Value: [0, 0, 40, 175])
//     AVP(Code: 258, Flags: 64, Length: 12, Value: [0, 0, 0, 4])
