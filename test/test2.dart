import 'dart:typed_data';
import 'package:test/test.dart';
// import 'lib/chatgpt2/diameter_message11.dart'; // Replace with the correct file name
// import 'package:dart_diameter/dart_diameter.dart';
import 'package:dart_diameter/chatgpt2/diameter_message11.dart';

void main() {
  group('AVP Tests - Additional Cases', () {
    test('AVP with large integer value', () {
      final largeValue = 0xFFFFFFFF;
      final avp = AVP(266, 0, 12, largeValue);
      final encoded = avp.encode();
      final decoded = AVP.decode(266, 0, encoded.length, encoded.sublist(8));

      expect(decoded.value, largeValue);
    });

    test('AVP with empty string', () {
      final avp = AVP(267, 0, 8, "");
      final encoded = avp.encode();
      final decoded = AVP.decode(267, 0, encoded.length, encoded.sublist(8));

      expect(decoded.value, "");
    });

    test('AVP with large raw data', () {
      final largeRawData =
          Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final avp = AVP(268, 0, 8 + largeRawData.length, largeRawData);
      final encoded = avp.encode();
      final decoded = AVP.decode(268, 0, encoded.length, encoded.sublist(8));

      expect(decoded.value, largeRawData);
    });

    test('AVP decode with incorrect length', () {
      final avp = AVP(269, 0, 16, "Test");
      final encoded = avp.encode();
      // Modify the length field in the encoded data to be invalid
      encoded[5] = 0x00; // Set the length field to a smaller value

      expect(() => AVP.decode(269, 0, encoded.length, encoded.sublist(8)),
          throwsA(isA<FormatException>()));
    });
  });

  group('DiameterMessage Tests - Additional Cases', () {
    test('DiameterMessage with no AVPs', () {
      final diameterMessage = DiameterMessage(
        version: 1,
        length: 20, // Minimum size for a DiameterMessage header
        flags: 0,
        commandCode: 272,
        applicationId: 16777216,
        hopByHopId: 123456,
        endToEndId: 654321,
        avps: [],
      );

      final encoded = diameterMessage.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.avps.isEmpty, isTrue);
    });

    test('DiameterMessage with many AVPs', () {
      final avps = List.generate(
        100,
        (i) => AVP(260 + i, 0, 12, i), // 100 AVPs with integer values
      );

      final diameterMessage = DiameterMessage(
        version: 1,
        length: 20 + avps.fold(0, (sum, avp) => sum + avp.length),
        flags: 0,
        commandCode: 272,
        applicationId: 16777216,
        hopByHopId: 123456,
        endToEndId: 654321,
        avps: avps,
      );

      final encoded = diameterMessage.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.avps.length, avps.length);
      for (int i = 0; i < avps.length; i++) {
        expect(decoded.avps[i].code, avps[i].code);
        expect(decoded.avps[i].value, avps[i].value);
      }
    });

    test('DiameterMessage with padding in AVPs', () {
      final avp1 = AVP(263, 0, 12, 12345);
      final avp2 = AVP(264, 0, 13, "Test");
      final diameterMessage = DiameterMessage(
        version: 1,
        length: 20 + avp1.length + avp2.length,
        flags: 0,
        commandCode: 272,
        applicationId: 16777216,
        hopByHopId: 123456,
        endToEndId: 654321,
        avps: [avp1, avp2],
      );

      final encoded = diameterMessage.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.avps.length, 2);
      expect(decoded.avps[0].value, avp1.value);
      expect(decoded.avps[1].value, avp2.value);
    });

    test('DiameterMessage decode with corrupt header', () {
      final message = DiameterMessage(
        version: 1,
        length: 20,
        flags: 0,
        commandCode: 272,
        applicationId: 16777216,
        hopByHopId: 123456,
        endToEndId: 654321,
        avps: [],
      );

      final encoded = message.encode();
      encoded[1] = 0xFF; // Corrupting the header

      expect(() => DiameterMessage.decode(encoded),
          throwsA(isA<FormatException>()));
    });

    test('DiameterMessage decode with unknown AVP code', () {
      final avp = AVP(99999, 0, 12, 42); // Unknown AVP code
      final diameterMessage = DiameterMessage(
        version: 1,
        length: 20 + avp.length,
        flags: 0,
        commandCode: 272,
        applicationId: 16777216,
        hopByHopId: 123456,
        endToEndId: 654321,
        avps: [avp],
      );

      final encoded = diameterMessage.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.avps.length, 1);
      expect(decoded.avps[0].code, 99999);
      expect(decoded.avps[0].value, 42);
    });
  });
}
