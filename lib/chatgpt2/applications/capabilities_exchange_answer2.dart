import 'dart:typed_data';
import '../diameter_message8.dart'; // Assuming this is the DiameterMessage class

import 'dart:typed_data';

import 'dart:typed_data';

class CapabilitiesExchangeAnswer {
  final int resultCode;
  final String originHost;
  final String originRealm;
  final int vendorId;
  final String productName;
  final int hopByHopId;
  final int endToEndId;

  CapabilitiesExchangeAnswer({
    required this.resultCode,
    required this.originHost,
    required this.originRealm,
    required this.vendorId,
    required this.productName,
    required this.hopByHopId,
    required this.endToEndId,
  });

  // Encode the CapabilitiesExchangeAnswer into a Diameter message
  Uint8List encode() {
    // First, encode the header and AVPs
    final avps = <Uint8List>[];

    // AVP: Result-Code (Code: 268, Flags: 0x40, Length: 8)
    avps.add(_encodeAvp(
        268,
        0x40,
        8,
        (ByteData(4)..setInt32(0, resultCode, Endian.big))
            .buffer
            .asUint8List()));

    // AVP: Origin-Host (Code: 264, Flags: 0x40)
    avps.add(
        _encodeAvp(264, 0x40, originHost.length + 4, originHost.codeUnits));

    // AVP: Origin-Realm (Code: 296, Flags: 0x40)
    avps.add(
        _encodeAvp(296, 0x40, originRealm.length + 4, originRealm.codeUnits));

    // AVP: Vendor-ID (Code: 266, Flags: 0x40, Length: 8)
    avps.add(_encodeAvp(266, 0x40, 8,
        (ByteData(4)..setInt32(0, vendorId, Endian.big)).buffer.asUint8List()));

    // AVP: Product-Name (Code: 267, Flags: 0x40)
    avps.add(
        _encodeAvp(267, 0x40, productName.length + 4, productName.codeUnits));

    // AVP: Hop-by-Hop ID (Code: 263, Flags: 0x40, Length: 8)
    avps.add(_encodeAvp(
        263,
        0x40,
        8,
        (ByteData(4)..setInt32(0, hopByHopId, Endian.big))
            .buffer
            .asUint8List()));

    // AVP: End-to-End ID (Code: 282, Flags: 0x40, Length: 8)
    avps.add(_encodeAvp(
        282,
        0x40,
        8,
        (ByteData(4)..setInt32(0, endToEndId, Endian.big))
            .buffer
            .asUint8List()));

    // Encode the Diameter message with command code 257 (Capabilities Exchange Answer)
    return DiameterMessage.toBytes(
      version: 1,
      commandCode: 257, // Capabilities Exchange Answer
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avps,
    );
  }

  // Helper function to encode an AVP
  Uint8List _encodeAvp(int code, int flags, int length, List<int> value) {
    final avpLength = _alignLength(length + 8); // Align to 4-byte multiple
    final avp = ByteData(avpLength);

    avp.setInt32(0, code, Endian.big); // AVP Code
    avp.setInt8(4, flags); // AVP Flags
    avp.setInt8(5, avpLength); // AVP Length
    avp.setInt16(
        6, avpLength - 8, Endian.big); // AVP Length excluding the header
    avp.buffer.asUint8List().setRange(8, avpLength, value); // Set value

    // If there's padding, we add it here
    if (avpLength > (length + 8)) {
      avp.buffer.asUint8List().setRange(
          length + 8, avpLength, List.filled(avpLength - (length + 8), 0));
    }

    return avp.buffer.asUint8List();
  }

  // Helper function to ensure AVP length is aligned to 4-byte multiple
  int _alignLength(int length) {
    return (length + 3) & ~3; // Round up to the next multiple of 4
  }

  @override
  String toString() {
    return 'CapabilitiesExchangeAnswer('
        'resultCode: $resultCode, '
        'originHost: $originHost, '
        'originRealm: $originRealm, '
        'vendorId: $vendorId, '
        'productName: $productName, '
        'hopByHopId: $hopByHopId, '
        'endToEndId: $endToEndId)';
  }
}

void main() async {
  // Example request data (CER) to generate a CEA from
  // final requestData = Uint8List.fromList([
  //   // Populate with byte data corresponding to a Diameter CER message
  // ]);

  // Decode the request (CER)
  final request = DiameterMessage.decode(cert_test);

  // Generate Capabilities Exchange Answer (CEA) based on the request
  final cea = CapabilitiesExchangeAnswer(
    resultCode: 2001, // Example Result Code: Success
    originHost: 'example.com',
    originRealm: 'example.com',
    vendorId: 10415, // Example Vendor ID
    productName: 'Diameter Server',
    hopByHopId: request.hopByHopId,
    endToEndId: request.endToEndId,
  );

  // Encode and print the CEA
  final ceaEncoded = cea.encode();
  print("Encoded CEA: $ceaEncoded");

  // Here you would send the encoded CEA to the client (using the server socket)
}

final cert_test = Uint8List.fromList([
  1,
  0,
  0,
  140,
  128,
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
  8,
  96,
  0,
  0,
  27,
  103,
  120,
  46,
  112,
  99,
  101,
  102,
  46,
  101,
  120,
  97,
  109,
  112,
  108,
  101,
  46,
  99,
  111,
  109,
  0,
  0,
  0,
  1,
  40,
  64,
  0,
  0,
  24,
  112,
  99,
  101,
  102,
  46,
  101,
  120,
  97,
  109,
  112,
  108,
  101,
  46,
  99,
  111,
  109,
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
  40,
  175,
  0,
  0,
  1,
  22,
  64,
  0,
  0,
  12,
  0,
  3,
  87,
  201,
  0,
  0,
  1,
  9,
  96,
  0,
  0,
  12,
  0,
  0,
  40,
  175,
  0,
  0,
  1,
  2,
  64,
  0,
  0,
  12,
  0,
  0,
  0,
  4
]);
