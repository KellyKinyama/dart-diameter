import 'dart:typed_data';

import 'avp.dart'; // Assuming AVP class is implemented in avp.dart.

/// A class representing an AVP grouping multiple AVPs together.
class AVPGrouped extends AVP {
  AVPGrouped.fromAVP(AVP a) : super.copy(a) {
    int offset = 0;
    List<int> raw = queryPayload();
    int i = 0;

    while (offset < raw.length) {
      int avpSize =
          AVP.decodeSize(Uint8List.fromList(raw), offset, raw.length - offset);
      if (avpSize == 0) {
        throw InvalidAVPLengthException(a);
      }
      offset += avpSize;
      i++;
    }

    if (offset > raw.length) {
      throw InvalidAVPLengthException(a);
    }
  }

  AVPGrouped(int code, List<AVP> grouped)
      : super.withPayload(code, _avpsToBytes(grouped));

  AVPGrouped.withVendor(int code, int vendorId, List<AVP> grouped)
      : super.withVendorPayload(code, vendorId, _avpsToBytes(grouped));

  List<AVP> queryAVPs() {
    int offset = 0;
    List<int> raw = queryPayload();
    int i = 0;

    while (offset < raw.length) {
      int avpSize =
          AVP.decodeSize(Uint8List.fromList(raw), offset, raw.length - offset);
      if (avpSize == 0) {
        return [];
      }
      offset += avpSize;
      i++;
    }

    List<AVP> avps = List<AVP>.filled(i, AVP(), growable: false);
    offset = 0;
    i = 0;

    while (offset < raw.length) {
      int avpSize =
          AVP.decodeSize(Uint8List.fromList(raw), offset, raw.length - offset);
      avps[i] = AVP();
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
