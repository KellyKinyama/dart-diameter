import 'dart:typed_data';

import 'diameter_avp.dart';
// import 'package:your_project/diameter_avp.dart';
// import 'package:your_project/avp_dictionary_data.dart';

class Unsigned64AVP extends DiameterAVP {
  late int data;

  Unsigned64AVP(int avpCode, int flags, int vendorId)
      : super(avpCode, flags, vendorId);

  Unsigned64AVP.fromDictionaryData(AVPDictionaryData dictData)
      : super.fromDictionaryData(dictData);

  @override
  void encodeData(ByteData buffer) {
    buffer.buffer.asByteData().setInt64(buffer.offsetInBytes, data);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    data = buffer.getInt64(buffer.offsetInBytes);
    addDataLength(length);
  }

  int getData() {
    return data;
  }

  @override
  void setData(String data) {
    this.data = int.parse(data);
    addDataLength(8);
  }

  @override
  void printData(StringBuffer sb) {
    sb.write(data);
  }
}
