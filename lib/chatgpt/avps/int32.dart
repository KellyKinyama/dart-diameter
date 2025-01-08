import 'dart:typed_data';

import '../avp.dart';

class AVP_Int32 extends DiameterAVP{
  AVP_Int32({required super.code, required super.flags, required super.length, required super.vendorId, required super.value});


  Uint8List encode(){
    return super.encode();
  }
}

void main(){
  
}