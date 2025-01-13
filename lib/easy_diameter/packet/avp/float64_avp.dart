import 'dart:typed_data';

// import 'package:your_project/diameter_avp.dart';
// import 'package:your_project/avp_dictionary_data.dart';

import 'diameter_avp.dart';

class Float64AVP extends DiameterAVP {
  late double data;

  Float64AVP(int avpCode, int flags, int vendorId) : super(avpCode, flags, vendorId);

  Float64AVP.fromDictionaryData(AVPDictionaryData dictData) : super.fromDictionaryData(dictData);

  @override
  void encodeData(ByteData buffer) {
    buffer.setFloat64(buffer.lengthInBytes, data, Endian.big);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    data = buffer.getFloat64(buffer.offsetInBytes, Endian.big);
    addDataLength(length);
  }

  double getData() {
    return data;
  }

  void setData(double data) {
    this.data = data;
    addDataLength(8);
  }

  @override
  void setDataFromString(String data) {
    this.data = double.parse(data);
    addDataLength(8);
  }

  @override
  void printData(StringBuffer sb) {
    sb.write(data);
  }
}
