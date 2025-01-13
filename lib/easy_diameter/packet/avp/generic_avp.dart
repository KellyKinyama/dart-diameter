import 'dart:typed_data';

// import 'package:your_project/diameter_avp.dart';
// import 'package:your_project/avp_dictionary_data.dart';

import 'diameter_avp.dart';

class GenericAVP extends DiameterAVP {
  @override
  // late Uint8List byteData;
  late List<int> byteData;

  GenericAVP(int avpCode, int flags, int vendorId)
      : super(avpCode, flags, vendorId) {
    name = "Unknown";
  }

  GenericAVP.fromDictionaryData(AVPDictionaryData dictData)
      : super.fromDictionaryData(dictData) {
    name = "Unknown";
  }

  @override
  void encodeData(ByteData buffer) {
    buffer.buffer.asUint8List().setAll(buffer.lengthInBytes, byteData);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    byteData = Uint8List(length);
    buffer.buffer.asUint8List().setAll(buffer.offsetInBytes, byteData);
    addDataLength(length);
  }

  @override
  void setData(String data) {
    byteData = Uint8List.fromList(data.codeUnits);
    addDataLength(data.length);
  }

  @override
  void printData(StringBuffer sb) {
    sb.write(String.fromCharCodes(byteData));
  }
}
