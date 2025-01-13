import 'dart:typed_data';

import '../diameter_message7.dart';

class CapabilitiesExchangeRequest {
  final DiameterMessage diameterMessage;

  CapabilitiesExchangeRequest({required this.diameterMessage});

  // Factory constructor to create a CER from raw data (decoded DiameterMessage)
  factory CapabilitiesExchangeRequest.decode(Uint8List data) {
    // Decode the Diameter message first
    final diameterMessage = DiameterMessage.decode(data);

    // Ensure that this is a valid CER by checking command code (257 for CER)
    if (diameterMessage.commandCode != 257) {
      throw FormatException(
          'Invalid Diameter command code for Capabilities Exchange Request');
    }

    return CapabilitiesExchangeRequest(diameterMessage: diameterMessage);
  }

  // Method to encode the Capabilities Exchange Request into a byte stream
  Uint8List encode() {
    final buffer = BytesBuilder();

    // Encode the DiameterMessage (CER is a Diameter message)
    buffer.add(diameterMessage.encode());

    return buffer.toBytes();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Capabilities Exchange Request:');
    buffer.writeln('  ${diameterMessage.toString()}');
    return buffer.toString();
  }

  // Utility to extract specific AVPs (e.g., Origin-Host, Session-Id)
  AVP? getSessionId() {
    return diameterMessage.avps.firstWhere(
      (avp) => avp.code == 263,
      orElse: () => AVP(263, 0, 0, []), // Return empty AVP if not found
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
  // Sample input: decoded Diameter message (using cert_test)
  final message = CapabilitiesExchangeRequest.decode(cert_test);

  // Print the decoded message (CER)
  print('Decoded Capabilities Exchange Request:');
  print(message);

  // Access specific AVPs
  final sessionId = message.getSessionId();
  print('Session-Id AVP: ${sessionId.toString()}');

  final originHost = message.getOriginHost();
  print('Origin-Host AVP: ${originHost.toString()}');

  final originRealm = message.getOriginRealm();
  print('Origin-Realm AVP: ${originRealm.toString()}');
}
