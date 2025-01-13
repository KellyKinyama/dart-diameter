import 'dart:typed_data';

import '../../utils/buffer_utilities.dart';
import 'diameter_avp.dart';
// import 'package:your_project/diameter_avp.dart';
// import 'package:your_project/avp_dictionary_data.dart';
// import 'package:your_project/diameter_parse_exception.dart';
// import 'package:your_project/buffer_utilities.dart';

class OctetStringAVP extends DiameterAVP {
  late String data;
  late List<int> byteData;

  OctetStringAVP(int avpCode, int flags, int vendorId)
      : super(avpCode, flags, vendorId);

  OctetStringAVP.fromDictionaryData(AVPDictionaryData dictData)
      : super.fromDictionaryData(dictData);

  @override
  void encodeData(ByteData buffer) {
    //buffer.buffer.asByteData().setUint8List(buffer.offsetInBytes, byteData);
  }

  @override
  void decodeData(ByteData buffer, int length) {
    byteData = buffer.buffer.asUint8List(buffer.offsetInBytes, length);
    data = String.fromCharCodes(byteData);
    addDataLength(length);
  }

  String getData() {
    return data;
  }

  @override
  void setData(String data) {
    this.data = data;
    this.byteData = Uint8List.fromList(data.codeUnits);
    addDataLength(data.length);
  }

  @override
  void printData(StringBuffer sb) {
    String dt = data.isNotEmpty
        ? data
        : BufferUtilities.byteToHexString(byteData, 0, byteData.length) +
            "(Hex)";
    sb.write(dt);
  }
}
