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

  if (a.code != 461) {
    throw "Expected: 461. Got: ${a.code}";
  }

  if (a.isMandatory != true) {
    throw "Expected isMandatory: true. Got: ${a.code}";
  }
  if (a.isPrivate != false) {
    throw "Expected isPrivate: false. Got: ${a.isPrivate}";
  }
  if (a.isVendor != false) {
    throw "Expected isVendor: false. Got: ${a.isVendor}";
  }
  if (a.length != 22) {
    throw "Expected length: 22. Got: ${a.length}";
  }
  if (utf8.decode(a.value) != "32251@3gpp.org") {
    throw "Expected value: true. Got: ${a.value}";
  }
  print("avp: $a");
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
