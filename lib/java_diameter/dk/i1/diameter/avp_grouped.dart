import 'dart:typed_data';
import 'avp.dart'; // Assuming AVP class is implemented in avp.dart.

/// A class representing an AVP grouping multiple AVPs together.
class AVPGrouped extends AVP {
  AVPGrouped.fromAVP(AVP a) : super.copy(a) {
    int offset = 0;
    List<int> raw = queryPayload();
    int i = 0;

    // Loop to check all AVPs within the grouped payload
    while (offset < raw.length) {
      int avpSize =
          AVP.decodeSize(Uint8List.fromList(raw), offset, raw.length - offset);
      if (avpSize == 0) {
        throw InvalidAVPLengthException(a); // If size is 0, throw exception
      }
      offset += avpSize;
      i++;
    }

    if (offset != raw.length) {
      throw InvalidAVPLengthException(a); // If we didn't consume all bytes
    }
  }

  AVPGrouped(int code, List<AVP> grouped)
      : super.withPayload(code, Uint8List.fromList(_avpsToBytes(grouped)));

  AVPGrouped.withVendor(int code, int vendorId, List<AVP> grouped)
      : super.withVendorPayload(
            code, vendorId, Uint8List.fromList(_avpsToBytes(grouped)));

  List<AVP> queryAVPs() {
    int offset = 0;
    List<int> raw = queryPayload();
    int i = 0;

    // First pass to count how many AVPs are in the payload
    while (offset < raw.length) {
      int avpSize =
          AVP.decodeSize(Uint8List.fromList(raw), offset, raw.length - offset);
      if (avpSize == 0) {
        return []; // If invalid size, return an empty list
      }
      offset += avpSize;
      i++;
    }

    // Initialize a list to store AVPs
    List<AVP> avps = List<AVP>.filled(i, AVP(Uint8List(0)),
        growable: false); // Fix here: Create AVPs with empty payload
    offset = 0;
    i = 0;

    // Second pass to decode the AVPs into their instances
    while (offset < raw.length) {
      int avpSize =
          AVP.decodeSize(Uint8List.fromList(raw), offset, raw.length - offset);
      avps[i] = AVP(Uint8List(0)); // Fix here: Create AVPs with empty payload
      avps[i].decode(Uint8List.fromList(raw), offset, avpSize);
      offset += avpSize;
      i++;
    }

    return avps;
  }

  void setAVPs(List<AVP> grouped) {
    setPayload(Uint8List.fromList(_avpsToBytes(grouped)));
  }

  static List<int> _avpsToBytes(List<AVP> grouped) {
    int bytes = grouped.fold(0, (sum, avp) => sum + avp.encodeSize());
    List<int> raw = List<int>.filled(bytes, 0);
    int offset = 0;

    // Encode each AVP into the byte array
    for (var avp in grouped) {
      offset += avp.encode(Uint8List.fromList(raw), offset);
    }

    return raw;
  }
}

/// Exception for invalid AVP length.
class InvalidAVPLengthException implements Exception {
  final AVP avp;

  InvalidAVPLengthException(this.avp);

  @override
  String toString() => 'Invalid AVP length for AVP: $avp';
}
