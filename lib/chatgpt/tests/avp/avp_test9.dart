import 'dart:convert';
import 'dart:typed_data';

import '../../avp9.dart';
import '../../avps/address.dart';
import '../../constants.dart';

void main() {
  //testDecodeFromBytes();
  //testDecodeFromAVP();
  //testDecodeEncodeHeader();
  //testDecodeEncodeHeaderWithVendor();
  testGroupedAVP();
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

  if (a.header.code != 461) {
    throw "Expected: 461. Got: ${a.header.code}";
  }

  // if (a.header.flags.isMandatory != true) {
  //   throw "Expected isMandatory: true. Got: ${a.header.flags.isMandatory}";
  // }
  // if (a.header.flags.isPrivate != false) {
  //   throw "Expected isPrivate: false. Got: ${a.header.flags.isPrivate}";
  // }
  // if (a.header.flags.isVendor != false) {
  //   throw "Expected isVendor: false. Got: ${a.header.flags.isVendor}";
  // }
  // if (a.header.length != 22) {
  //   throw "Expected length: 22. Got: ${a.header.length}";
  // }
  // if (utf8.decode(a.payload) != "32251@3gpp.org") {
  //   throw "Expected value: true. Got: ${a.payload}";
  // }

  if (a.header.code != 461) throw "Expected 100. Got ${a.header.code}";
  if (a.header.length != 22) throw "Expected 12. Got ${a.header.length}";
  if (a.header.flags.isVendor != false) {
    throw "Expected false. Got ${a.header.flags.isVendor}";
  }
  if (a.header.flags.isMandatory != true) {
    throw "Expected true. Got ${a.header.flags.isMandatory}";
  }
  if (a.header.flags.isPrivate != false) {
    throw "Expected false. Got ${a.header.flags.isPrivate}";
  }
  if (a.header.flags.isVendor != false) {
    throw "Expected false. Got ${a.header.flags.isVendor}";
  }
  print("avp: $a");
  print("""
""");
  print("Encoded:  ${a.encode()}");
  print("Expected: $avpBytes");
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
  //final a2 = DiameterAVP.fromAVP(a1);

  // // Assertions
  // assert(a1.code == a2.code, 'Code mismatch');
  // assert(a1.isMandatory == a2.isMandatory, 'Mandatory flag mismatch');
  // assert(a1.isPrivate == a2.isPrivate, 'Private flag mismatch');
  // assert(a1.isVendor == a2.isVendor, 'Vendor flag mismatch');
  // assert(a1.length == a2.length, 'Length mismatch');
  // assert(a1.value == a2.value, 'Value mismatch');

  print('Test passed: Original and copied AVPs are identical.');
}

// void testCreateAddressType() {
//   // Create an "Address" type AVP for IPv4
//   final avpSGSNAddress = AvpAddress(code: Constants.AVP_TGPP_SGSN_ADDRESS);

//   // Set value for IPv4
//   avpSGSNAddress.setValue("193.16.219.96");

//   // Assert parsed value
//   final parsedSGSN = avpSGSNAddress.parsedValue;
//   assert(parsedSGSN.item1 == 1); // Family 1 = IPv4
//   assert(parsedSGSN.item2 == "193.16.219.96");

//   // Assert payload
//   final expectedPayloadIPv4 =
//       Uint8List.fromList([0x00, 0x01, 0xc1, 0x10, 0xdb, 0x60]);
//   assert(Uint8ListEquality().equals(avpSGSNAddress.value, expectedPayloadIPv4));

//   // Create an "Address" type AVP for IPv6
//   final avpPDPAddress = AvpAddress(code: Constants.AVP_TGPP_PDP_ADDRESS);

//   // Set value for IPv6
//   avpPDPAddress.setValue("8b71:8c8a:1e29:716a:6184:7966:fd43:4200");

//   // Assert parsed value
//   final parsedPDP = avpPDPAddress.parsedValue;
//   assert(parsedPDP.item1 == 2); // Family 2 = IPv6
//   assert(parsedPDP.item2 == "8b71:8c8a:1e29:716a:6184:7966:fd43:4200");

//   // Assert payload
//   final expectedPayloadIPv6 = Uint8List.fromList([
//     0x00,
//     0x02,
//     0x8b,
//     0x71,
//     0x8c,
//     0x8a,
//     0x1e,
//     0x29,
//     0x71,
//     0x6a,
//     0x61,
//     0x84,
//     0x79,
//     0x66,
//     0xfd,
//     0x43,
//     0x42,
//     0x00
//   ]);
//   assert(Uint8ListEquality().equals(avpPDPAddress.value, expectedPayloadIPv6));

//   // Create an "Address" type AVP for E.164
//   final avpSMSCAddress = AvpAddress(code: Constants.AVP_TGPP_SMSC_ADDRESS);

//   // Set value for E.164
//   avpSMSCAddress.setValue("48507909008");

//   // Assert parsed value
//   final parsedSMSC = avpSMSCAddress.parsedValue;
//   assert(parsedSMSC.item1 == 8); // Family 8 = E.164
//   assert(parsedSMSC.item2 == "48507909008");

//   // Assert payload
//   final expectedPayloadE164 = Uint8List.fromList([
//     0x00,
//     0x08,
//     0x34,
//     0x38,
//     0x35,
//     0x30,
//     0x37,
//     0x39,
//     0x30,
//     0x39,
//     0x30,
//     0x30,
//     0x38
//   ]);
//   assert(Uint8ListEquality().equals(avpSMSCAddress.value, expectedPayloadE164));
// }

class Uint8ListEquality {
  bool equals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

void testDecodeEncodeHeader() {
  final data = Uint8List.fromList([
    0x00, 0x00, 0x00, 0x64, // command code
    0x40, 0x00, 0x00, 0x0C, // flags, length
  ]);

  var header = DiameterAVPHeader.decode(data);

  if (header.code != 100) throw "Expected 100. Got ${header.code}";
  if (header.length != 12) throw "Expected 12. Got ${header.length}";
  if (header.flags.isVendor != false) {
    throw "Expected false. Got ${header.flags.isVendor}";
  }
  if (header.flags.isMandatory != true) {
    throw "Expected true. Got ${header.flags.isMandatory}";
  }
  if (header.flags.isPrivate != false) {
    throw "Expected false. Got ${header.flags.isPrivate}";
  }
  if (header.vendorId != 0) throw "Expected 100. Got ${header.vendorId}";
  print(header);
  print("""
""");
  print("Encoded:  ${header.encode()}");
  print("Expected: $data");
}

void testDecodeEncodeHeaderWithVendor() {
  final data = Uint8List.fromList([
    0x00, 0x00, 0x00, 0x64, // command code
    0x80, 0x00, 0x00, 0x0C, // flags, length
    0x00, 0x00, 0x00, 0xC8, // vendor_id
  ]);

  var header = DiameterAVPHeader.decode(data);

  // assert_eq!(header.code, 100);
  // assert_eq!(header.length, 12);
  // assert_eq!(header.flags.vendor, true);
  // assert_eq!(header.flags.mandatory, false);
  // assert_eq!(header.flags.private, false);
  // assert_eq!(header.vendor_id, Some(200));

  if (header.code != 100) throw "Expected 100. Got ${header.code}";
  if (header.length != 12) throw "Expected 12. Got ${header.length}";
  if (header.flags.isVendor != true) {
    throw "Expected true. Got ${header.flags.isVendor}";
  }
  if (header.flags.isMandatory != false) {
    throw "Expected true. Got ${header.flags.isMandatory}";
  }
  if (header.flags.isPrivate != false) {
    throw "Expected false. Got ${header.flags.isPrivate}";
  }
  if (header.vendorId != 200) throw "Expected 200. Got ${header.vendorId}";
  print(header);
}

// void testGroupedAVP() {
//   Uint8List data = Uint8List.fromList([
//     0x68,
//     0x65,
//     0x6c,
//     0x6c,
//     0x6f,
//     0x2c,
//     0x20,
//     0x77,
//     0x6f,
//     0x72,
//     0x6c,
//     0x64,
//   ]);
//   var gAvp = GroupedAVP.decode(data);
//   print("Grouped avp: $gAvp");
// }

void testGroupedAVP() {
  // Create nested AVPs
  final innerAvp1 = DiameterAVP(
    header: DiameterAVPHeader(
      code: 1,
      flags: DiameterAVPFlags.fromAvpFlags(
        isMandatory: true,
        isPrivate: false,
        isVendor: false,
      ),
      length: 12,
    ),
    payload: IntegerAVP(12345),
  );

  final innerAvp2 = DiameterAVP(
    header: DiameterAVPHeader(
      code: 461,
      flags: DiameterAVPFlags.fromAvpFlags(
        isMandatory: true,
        isPrivate: false,
        isVendor: false,
      ),
      length: 16,
    ),
    payload: StringAVP("test"),
  );

  // Create a GroupedAVP
  final groupedAvp = GroupedAVP([innerAvp1, innerAvp2]);

  // Encode the GroupedAVP
  final groupedAvpData = groupedAvp.value;

  // Debugging: Print the raw bytes of the GroupedAVP
  print('Encoded GroupedAVP data: $groupedAvpData');

  // Decode the GroupedAVP
  try {
    final decodedGroupedAvp = GroupedAVP.decode(groupedAvpData);
    print("Decoded GroupedAVP: $decodedGroupedAvp");
  } catch (e, stackTrace) {
    print("Error decoding GroupedAVP: $e");
    print("Stack trace: $stackTrace");
  }
}




// void testGroupedAVP() {
//   // Create embedded AVPs
//   final avp1 = DiameterAVP(
//     header: DiameterAVPHeader(
//       code: 1,
//       flags: DiameterAVPFlags.fromAvpFlags(isMandatory: true, isPrivate: false, isVendor: false),
//       length: 12,
//     ),
//     payload: Uint8List.fromList(utf8.encode('test1')),
//   );

//   final avp2 = DiameterAVP(
//     header: DiameterAVPHeader(
//       code: 2,
//       flags: DiameterAVPFlags.fromAvpFlags(isMandatory: true, isPrivate: false, isVendor: false),
//       length: 12,
//     ),
//     payload: Uint8List.fromList(utf8.encode('test2')),
//   );

//   // Create a GroupedAVP containing the above AVPs
//   final groupedAVP = GroupedAVP([avp1, avp2]);

//   // Encode the GroupedAVP
//   final encodedGroupedAVP = groupedAVP.encodeTo();
//   print('Encoded GroupedAVP: $encodedGroupedAVP');

//   // Decode the GroupedAVP
//   final decodedGroupedAVP = GroupedAVP.decodeFrom(Uint8List.fromList(encodedGroupedAVP));
//   print('Decoded GroupedAVP contains ${decodedGroupedAVP.avps.length} AVPs:');
//   for (var avp in decodedGroupedAVP.avps) {
//     print(' - AVP Code: ${avp.header.code}, Value: ${utf8.decode(avp.payload)}');
//   }
// }