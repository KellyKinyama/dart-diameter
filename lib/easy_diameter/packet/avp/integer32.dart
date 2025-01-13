import 'dart:typed_data';

import 'diameter_avp.dart';

class Integer32AVP extends DiameterAVP {
  late int data;

  Integer32AVP(int avpCode, int flags, int vendorId)
      : super(avpCode, flags, vendorId);

  Integer32AVP.fromDictionaryData(AVPDictionaryData dictData)
      : super.fromDictionaryData(dictData);

  @override
  void encodeData(ByteData buffer) {
    buffer.buffer.asByteData().setInt32(buffer.offsetInBytes, data, Endian.big);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    data =
        buffer.buffer.asByteData().getInt32(buffer.offsetInBytes, Endian.big);
    addDataLength(length);
  }

  int getData() {
    return data;
  }

  void setData(int data) {
    this.data = data;
    addDataLength(4);
  }

  @override
  void printData(StringBuffer sb) {
    sb.write(data);
  }
}
