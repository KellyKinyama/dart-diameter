import 'dart:typed_data';

import '../../avp.dart';

void main() {
  var avp = DiameterAVP.decode(data);
  print("avp: $avp");
  // final integerAVP = DiameterAVP.integerAVP(2, 12345);
  // print("Integer avp: $integerAVP");
  // print("Encoded: ${integerAVP.encode()}");
}

Uint8List data = Uint8List.fromList([
  0, 0, 1, 3, 64, 0, 0, 12, 0, 0, 0, 3, 0, 0, 1, 41, 0, 0, 0, 20, 0, 0, 1, 42,
  0, 0, 0, 12, 0, 0, 7, -47, 0, 0, 0,
  1, 0, 0, 0, 26, 109, 111, 98, 105, 99, 101, 110, 116, 115, 45, 100, 105, 97,
  109, 101, 116, 101, 114, 0, 0, 0,
  0, 0,
  123, //avpCode
  -64, 0, 0, 15, 0, 0, 0,
  1, //vendorId
  88, 88, 88, 0
]);
