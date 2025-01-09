import 'dart:convert';
import 'dart:typed_data';

import '../../avp.dart';

void main() {
  testDecodeFromBytes();
  testDecodeFromAVP();
}

void testDecodeFromBytes() {
  final avpBytes = Uint8List.fromList([
    0x00, 0x00, 0x01, 0xCD, // Code
    0x40, // Flags
    0x00, 0x00, 0x16, // Length
    0x33, 0x32, 0x32, 0x35, // Value: "32251@3gpp.org"
    0x31, 0x40, 0x33, 0x67,
    0x70, 0x70, 0x2E, 0x6F,
    0x72, 0x67, 0x00, 0x00 // Padding
  ]);
  final a = DiameterAVP.decode(avpBytes);

  assert(a.code == 461);
  assert(a.isMandatory == true);
  assert(a.isPrivate == false);
  assert(a.isVendor == false);
  assert(a.length == 22);
  assert(a.value == "32251@3gpp.org");
  print("avp: $a");
  print("avp code: ${utf8.decode(a.value)}");
}

void testDecodeFromAVP() {
  // Original AVP bytes
  final avpBytes = Uint8List.fromList([
    0x00, 0x00, 0x01, 0xCD, // Code
    0x40, // Flags
    0x00, 0x00, 0x16, // Length
    0x33, 0x32, 0x32, 0x35, // Value: "32251@3gpp.org"
    0x31, 0x40, 0x33, 0x67,
    0x70, 0x70, 0x2E, 0x6F,
    0x72, 0x67, 0x00, 0x00 // Padding
  ]);

  // Create original AVP
  final a1 = DiameterAVP.decode(avpBytes);

  // Create a copy of the AVP
  final a2 = DiameterAVP.fromAVP(a1);

  // Assertions
  assert(a1.code == a2.code, 'Code mismatch');
  assert(a1.isMandatory == a2.isMandatory, 'Mandatory flag mismatch');
  assert(a1.isPrivate == a2.isPrivate, 'Private flag mismatch');
  assert(a1.isVendor == a2.isVendor, 'Vendor flag mismatch');
  assert(a1.length == a2.length, 'Length mismatch');
  assert(a1.value == a2.value, 'Value mismatch');

  print('Test passed: Original and copied AVPs are identical.');
}
