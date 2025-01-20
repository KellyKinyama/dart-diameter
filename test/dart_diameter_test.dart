import 'dart:typed_data';
import 'package:test/test.dart';
// import 'lib/chatgpt2/diameter_message11.dart'; // Replace with the correct file name
// import 'package:dart_diameter/dart_diameter.dart';
import 'package:dart_diameter/chatgpt2/diameter_message11.dart';

void main() {
  group('AVP Tests', () {
    test('Encode and decode integer AVP', () {
      final avp = AVP(263, 0, 12, 1234567890); // Example AVP with integer value
      final encoded = avp.encode();
      final decoded = AVP.decode(263, 0, encoded.length, encoded.sublist(8));

      expect(decoded.code, avp.code);
      expect(decoded.flags, avp.flags);
      expect(decoded.length, avp.length);
      expect(decoded.value, avp.value);
    });

    test('Encode and decode string AVP', () {
      final avp = AVP(264, 0, 14, "Hello"); // Example AVP with string value
      final encoded = avp.encode();
      final decoded = AVP.decode(264, 0, encoded.length, encoded.sublist(8));

      expect(decoded.code, avp.code);
      expect(decoded.flags, avp.flags);
      expect(decoded.length, avp.length);
      expect(decoded.value, avp.value);
    });

    test('Encode and decode raw byte AVP', () {
      final rawData = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final avp = AVP(265, 0, 12, rawData); // Example AVP with raw data
      final encoded = avp.encode();
      final decoded = AVP.decode(265, 0, encoded.length, encoded.sublist(8));

      expect(decoded.code, avp.code);
      expect(decoded.flags, avp.flags);
      expect(decoded.length, avp.length);
      expect(decoded.value, avp.value);
    });
  });

  group('DiameterMessage Tests', () {
    test('Encode and decode DiameterMessage', () {
      final avp1 = AVP(263, 0, 12, 1234567890);
      final avp2 = AVP(264, 0, 14, "Test");
      final diameterMessage = DiameterMessage(
        version: 1,
        length: 48,
        flags: 0,
        commandCode: 272,
        applicationId: 16777216,
        hopByHopId: 123456,
        endToEndId: 654321,
        avps: [avp1, avp2],
      );

      final encoded = diameterMessage.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.version, diameterMessage.version);
      expect(decoded.length, diameterMessage.length);
      expect(decoded.flags, diameterMessage.flags);
      expect(decoded.commandCode, diameterMessage.commandCode);
      expect(decoded.applicationId, diameterMessage.applicationId);
      expect(decoded.hopByHopId, diameterMessage.hopByHopId);
      expect(decoded.endToEndId, diameterMessage.endToEndId);
      expect(decoded.avps.length, diameterMessage.avps.length);

      for (int i = 0; i < diameterMessage.avps.length; i++) {
        final originalAvp = diameterMessage.avps[i];
        final decodedAvp = decoded.avps[i];
        expect(decodedAvp.code, originalAvp.code);
        expect(decodedAvp.flags, originalAvp.flags);
        expect(decodedAvp.length, originalAvp.length);
        expect(decodedAvp.value, originalAvp.value);
      }
    });

    test('Decode with padding', () {
      final avp1 = AVP(263, 0, 12, 1234567890);
      final avp2 = AVP(264, 0, 14, "PaddingTest");
      final diameterMessage = DiameterMessage(
        version: 1,
        length: 60,
        flags: 0,
        commandCode: 272,
        applicationId: 16777216,
        hopByHopId: 123456,
        endToEndId: 654321,
        avps: [avp1, avp2],
      );

      final encoded = diameterMessage.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.avps.length, diameterMessage.avps.length);
      expect(decoded.avps[1].value, avp2.value);
    });

    test('Invalid DiameterMessage decode throws exception', () {
      final invalidData =
          Uint8List(15); // Too short for a valid DiameterMessage

      expect(() => DiameterMessage.decode(invalidData),
          throwsA(isA<FormatException>()));
    });

    test('Invalid AVP length throws exception', () {
      final invalidData = Uint8List.fromList([
        1, 0, 0, 20, // Header
        0, 0, 1, 44, // AVP header with invalid length
      ]);

      expect(() => DiameterMessage.decode(invalidData),
          throwsA(isA<FormatException>()));
    });
  });
}
