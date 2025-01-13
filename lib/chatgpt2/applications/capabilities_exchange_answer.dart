import 'dart:typed_data';

import '../diameter_message7.dart';

class CapabilitiesExchangeAnswer {
  final DiameterMessage diameterMessage;

  CapabilitiesExchangeAnswer({required this.diameterMessage});

  // Factory constructor to create a CEA from raw data (decoded DiameterMessage)
  factory CapabilitiesExchangeAnswer.decode(Uint8List data) {
    final diameterMessage = DiameterMessage.decode(data);

    print('Command Code: ${diameterMessage.commandCode}'); // Debugging output

    if (diameterMessage.commandCode != 257 &&
        diameterMessage.commandCode != 258) {
      throw FormatException(
          'Invalid Diameter command code for Capabilities Exchange (expected 257 or 258)');
    }

    return CapabilitiesExchangeAnswer(diameterMessage: diameterMessage);
  }

  // Method to encode the Capabilities Exchange Answer into a byte stream
  Uint8List encode() {
    final buffer = BytesBuilder();

    // Encode the DiameterMessage (CEA is a Diameter message)
    buffer.add(diameterMessage.encode());

    return buffer.toBytes();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Capabilities Exchange Answer:');
    buffer.writeln('  ${diameterMessage.toString()}');
    return buffer.toString();
  }

  // Utility to extract specific AVPs (e.g., Result-Code, Origin-Host)
  AVP? getResultCode() {
    return diameterMessage.avps.firstWhere(
      (avp) => avp.code == 268,
      orElse: () => AVP(268, 0, 0, []), // Return empty AVP if not found
    );
  }

  AVP? getOriginHost() {
    return diameterMessage.avps.firstWhere(
      (avp) => avp.code == 264,
      orElse: () => AVP(264, 0, 0, []), // Return empty AVP if not found
    );
  }

  AVP? getOriginRealm() {
    return diameterMessage.avps.firstWhere(
      (avp) => avp.code == 296,
      orElse: () => AVP(296, 0, 0, []), // Return empty AVP if not found
    );
  }
}

void main() {
  // Sample input: decoded Diameter message for CEA (using cert_test_answer)
  final message = CapabilitiesExchangeAnswer.decode(cert_test_answer);

  // Print the decoded message (CEA)
  print('Decoded Capabilities Exchange Answer:');
  print(message);

  // Access specific AVPs
  final resultCode = message.getResultCode();
  print('Result-Code AVP: ${resultCode.toString()}');

  final originHost = message.getOriginHost();
  print('Origin-Host AVP: ${originHost.toString()}');

  final originRealm = message.getOriginRealm();
  print('Origin-Realm AVP: ${originRealm.toString()}');
}

final cert_test_answer = Uint8List.fromList([
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
