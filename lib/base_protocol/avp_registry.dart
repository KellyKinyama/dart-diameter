import 'dart:convert';
import 'dart:typed_data';

import 'diameter_avp.dart';

class AVPRegistry {
  static DiameterAVP decodeAVP(Uint8List data) {
    final avp = DiameterAVP.decode(data);

    switch (avp.code) {
      case 264: // Host-Identity
        return DiameterAVP.stringAVP(avp.code, utf8.decode(avp.value),
            flags: avp.flags, vendorId: avp.vendorId);
      case 266: // Vendor-Id
        return DiameterAVP.integerAVP(
            avp.code, ByteData.sublistView(avp.value).getUint32(0, Endian.big),
            flags: avp.flags, vendorId: avp.vendorId);
      // Add more AVPs here...
      default:
        return avp; // Return raw AVP if not recognized
    }
  }
}

final newAVP = DiameterAVP.stringAVP(999, 'NewFeatureSupport');
