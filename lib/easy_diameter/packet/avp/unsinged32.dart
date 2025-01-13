import 'dart:typed_data';
// import 'package:your_project/diameter_avp.dart';
// import 'package:your_project/avp_dictionary_data.dart';
// import 'package:your_project/buffer_utilities.dart';

import '../../utils/buffer_utilities.dart';
import 'diameter_avp.dart';

class Unsigned32AVP extends DiameterAVP {
  late int data;

  Unsigned32AVP(int avpCode, int flags, int vendorId)
      : super(avpCode, flags, vendorId);

  Unsigned32AVP.fromDictionaryData(AVPDictionaryData dictData)
      : super.fromDictionaryData(dictData);

  @override
  void encodeData(ByteData buffer) {
    buffer.buffer.asByteData().setInt32(buffer.offsetInBytes, data);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    data = BufferUtilities.get4BytesAsUnsigned32(buffer);
    addDataLength(length);
  }

  int getData() {
    return data;
  }

  @override
  void setData(String data) {
    this.data = int.parse(data);
    addDataLength(4);
  }

  @override
  void printData(StringBuffer sb) {
    sb.write(data);
  }
}
