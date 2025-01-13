import 'dart:typed_data';

// import 'package:your_project/diameter_avp.dart';
// import 'package:your_project/avp_dictionary_data.dart';

import 'diameter_avp.dart';

class Float32AVP extends DiameterAVP {
  late double data;

  Float32AVP(int avpCode, int flags, int vendorId)
      : super(avpCode, flags, vendorId);

  Float32AVP.fromDictionaryData(AVPDictionaryData dictData)
      : super.fromDictionaryData(dictData);

  @override
  void encodeData(ByteData buffer) {
    buffer.setFloat32(buffer.lengthInBytes, data, Endian.big);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    data = buffer.getFloat32(buffer.offsetInBytes, Endian.big);
    addDataLength(length);
  }

  double getData() {
    return data;
  }

  @override
  void setData(double data) {
    this.data = data;
    addDataLength(4);
  }

  @override
  void setDataFromString(String data) {
    this.data = double.parse(data);
    addDataLength(4);
  }

  @override
  void printData(StringBuffer sb) {
    sb.write(data);
  }
}
