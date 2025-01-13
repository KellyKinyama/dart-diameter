import 'dart:typed_data';

import 'package:dart_diameter/easy_diameter/utils/buffer_utilities.dart';

import '../../utils/protocol_defintions.dart';
import 'diameter_avp.dart';
import 'factory/avp_factory.dart';

class GroupedAVP extends DiameterAVP {
  List<DiameterAVP> avpList= [];

  GroupedAVP(int avpCode, int flags, int vendorId) : super(avpCode, flags, vendorId) {
    avpList = [];
  }

// factory GroupedAVP.fromDictionary(AVPDictionaryData dictData){
//  return  GroupedAVP(AVPDictionaryData dictData) : super(dictData);
  
// }

  @override
  void encodeData(ByteData buffer) {
    for (DiameterAVP avp in avpList) {
      avp.encode(buffer);
    }
  }

  @override
  void decodeData(ByteData buffer, int length) {
    int index = 0;
    int avpCode;
    int avpLength;
    int flags;
    int vendorId;
    int dataLength;

    while (index < length) {
      avpCode = BufferUtilities.get4BytesAsUnsigned32(buffer);
      flags = buffer.getUint8(index++);
      if ((flags & ProtocolDefinitions.AVP_MASK_RESERVED) != 0) {
        throw DiameterParseException(
            ProtocolDefinitions.RC_DIAMETER_INVALID_AVP_BITS, 'Invalid AVP bits for the AVP = $avpCode');
      }

      avpLength = BufferUtilities.get3BytesFromBuffer(buffer);
      if ((flags & DiameterAVP.AVP_MASK_BIT_V) != 0) {
        vendorId = BufferUtilities.get4BytesAsUnsigned32(buffer);
        dataLength = avpLength - DiameterAVP.AVP_HDR_LEN_WITH_VENDOR;
      } else {
        vendorId = 0;
        dataLength = avpLength - DiameterAVP.AVP_HDR_LEN_WITHOUT_VENDOR;
      }

      if (dataLength > avpLength || (buffer.lengthInBytes - index) < dataLength) {
        int len = (buffer.lengthInBytes - index < dataLength) ? buffer.lengthInBytes - index : avpLength;
        List<int> failedAVPData = buffer.buffer.asUint8List(index, len);
        throw DiameterParseException(ProtocolDefinitions.RC_DIAMETER_INVALID_AVP_LENGTH, 'Not enough AVP data remaining');
      }

      int padding = BufferUtilities.calculatePadding(avpLength);
      AVPFactory factory = AVPFactory.getAVPFactory(avpCode, vendorId);
      DiameterAVP avp = factory.createAVP(avpCode, flags, vendorId);

      avp.decodeData(buffer, dataLength);
      index += padding;
      avpList.add(avp);
      index += avp.avpLength;
    }
  }

  void setList(List<DiameterAVP> avpList) {
    this.avpList = avpList;
    for (DiameterAVP avp in avpList) {
      dataLength += avp.avpLength;
    }
    avpLength += dataLength;
  }

  void addAVP(DiameterAVP avp) {
    avpList.add(avp);
    dataLength += avp.avpLength;
    avpLength += avp.avpLength;
  }

  // @override
  // void printData(StringBuffer sb) {
  //   for (DiameterAVP avp in avpList) {
  //     sb.write("\n      ");
  //     avp.printContent(sb);
  //   }
  // }

 // @override
  void setData(String data) {
    // Useless for Grouped AVP
  }
}
