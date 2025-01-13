import 'dart:typed_data';

import 'diameter_avp.dart';

class Integer64AVP extends DiameterAVP {
  late int data;

  Integer64AVP(int avpCode, int flags, int vendorId)
      : super(avpCode, flags, vendorId);

  Integer64AVP.fromDictionaryData(AVPDictionaryData dictData)
      : super.fromDictionaryData(dictData);

  @override
  void encodeData(ByteData buffer) {
    buffer.buffer.asByteData().setInt32(buffer.offsetInBytes, data, Endian.big);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    data =
        buffer.buffer.asByteData().getInt64(buffer.offsetInBytes, Endian.big);
    addDataLength(length);
  }

  int getData() {
    return data;
  }

  void setData(int data) {
    this.data = data;
    addDataLength(8);
  }

  @override
  void printData(StringBuffer sb) {
    sb.write(data);
  }
}
