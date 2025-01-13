import 'dart:typed_data';
import 'dart:convert';

class AttributeInfo {
  // Define attributes as per your dictionary values in C#
}

class Avp {
  final int avpCode;
  final bool isVendorSpecific;
  final int vendorId;
  final List<Avp> groupedAvps;

  Avp({
    required this.avpCode,
    this.isVendorSpecific = false,
    this.vendorId = 0,
    this.groupedAvps = const [],
  });
}

Uint8List getGroupedAvpBytes(Avp gAvp, Map<int, AttributeInfo> dict) {
  // Destination offset
  int destOffset = 0;

  int avpCode = gAvp.avpCode;

  // Preallocate a buffer size (adjust size as necessary)
  Uint8List groupedAvpBytes = Uint8List(1024);
  ByteData byteData = ByteData.sublistView(groupedAvpBytes);

  // Copy grouped AVP code to bytes (network byte order)
  byteData.setInt32(destOffset, avpCode, Endian.big);
  destOffset += 4;

  // Set Flags for the AVP (AvpFlags {V M P r r r r r})
  int gAvpFlags = 0;
  if (gAvp.isVendorSpecific) gAvpFlags |= 1 << 7; // Set Vendor-Specific bit
  if (true) gAvpFlags |= 1 << 6; // Assuming isMandatory is true
  byteData.setUint8(destOffset, gAvpFlags);
  destOffset += 1;

  // Leaving 3 bytes placeholder for Length of Grouped AVP
  destOffset += 3;

  // Handle Vendor-Specific
  if (gAvp.isVendorSpecific) {
    byteData.setInt32(destOffset, gAvp.vendorId, Endian.big);
    destOffset += 4;
  }

  // Copy all AVPs inside the Grouped AVP
  for (var avp in gAvp.groupedAvps) {
    Uint8List avpBytes = getAvpBytes(avp, dict);
    groupedAvpBytes.setRange(destOffset, destOffset + avpBytes.length, avpBytes);
    destOffset += avpBytes.length;
  }

  // Set the Length of Grouped AVP
  int lengthOfGroupedAvp = destOffset;
  byteData.setUint8(5, (lengthOfGroupedAvp >> 16) & 0xFF);
  byteData.setUint8(6, (lengthOfGroupedAvp >> 8) & 0xFF);
  byteData.setUint8(7, lengthOfGroupedAvp & 0xFF);

  // Create the final output with exact size
  return Uint8List.sublistView(groupedAvpBytes, 0, destOffset);
}

Uint8List getAvpBytes(Avp avp, Map<int, AttributeInfo> dict) {
  // Replace with the actual AVP encoding logic
  // This is a placeholder example to encode an AVP
  return Uint8List.fromList(utf8.encode('Encoded AVP'));
}
