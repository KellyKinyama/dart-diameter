import 'dart:typed_data';

import '../../avp.dart';

void main() {
  // Uint8List data = Uint8List.fromList([0x7f, 0xff, 0xff, 0xff]);
  // var avp = DiameterAVP.decode(data);
  // print("Integer avp: $avp");
  final integerAVP = DiameterAVP.integerAVP(2, 12345);
  print("Integer avp: $integerAVP");
  print("Encoded: ${integerAVP.encode()}");
}
