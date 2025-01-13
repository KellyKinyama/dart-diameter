import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import '../../chatgpt/avps/address.dart';
import '../packet/avp/diameter_avp.dart';
import '../packet/avp/factory/avp_factory.dart';
import '../packet/avp/float32_avp.dart';
import '../packet/avp/float64_avp.dart';
import '../packet/avp/grouped_avp.dart';
import '../packet/avp/integer32.dart';
import '../packet/avp/integer64.dart';
import '../packet/avp/octet_string.dart';
import '../packet/avp/unsigned64.dart';
import '../packet/avp/unsinged32.dart';
import '../utils/buffer_utilities.dart';
import '../utils/protocol_defintions.dart';
import 'diameter_header.dart';

// import 'package:your_package/diameter_header.dart'; // Assuming this is a custom class
// import 'package:your_package/avp.dart'; // Assuming this includes all AVP types

class DiameterMessage {
  String? name;
  DiameterHeader header;
  List<DiameterAVP> avpList = [];
  late Uint8List packet;

  DiameterMessage(this.header);

  DiameterMessage.empty()
      : header = DiameterHeader(),
        avpList = [];

  Uint8List encodePacket() {
    packet = Uint8List(getMessageLength());
    final buffer = ByteData.sublistView(packet);
    header.encode(buffer);
    for (var avp in avpList) {
      avp.encode(buffer);
    }
    return packet;
  }

  static DiameterMessage decodePacket(Uint8List packet) {
    final buffer = ByteData.sublistView(packet);
    final header = decodePacketForHeader(buffer);
    final message = DiameterMessage(header);
    decodePacketForAVPs(buffer, message);
    return message;
  }

  static DiameterHeader decodePacketForHeader(ByteData buffer) {
    int version = buffer.getUint8(0);
    int length = BufferUtilities.get3BytesFromBuffer(buffer);
    int flags = buffer.getUint8(1);
    int commandCode = BufferUtilities.get3BytesFromBuffer(buffer);
    int applicationId = BufferUtilities.get4BytesAsUnsigned32(buffer);
    int hopByHopId = BufferUtilities.get4BytesAsUnsigned32(buffer);
    int endToEndId = BufferUtilities.get4BytesAsUnsigned32(buffer);

    DiameterHeader header = DiameterHeader(
        version, flags, commandCode, applicationId, hopByHopId, endToEndId);
    header.setMessageLength(length);

    if (version != ProtocolDefinitions.DIAMETER_VERSION) {
      throw DiameterParseException(
          ProtocolDefinitions.RC_DIAMETER_UNSUPPORTED_VERSION,
          header,
          "Unsupported version = $version");
    }

    if (length > buffer.lengthInBytes) {
      throw DiameterParseException(
          ProtocolDefinitions.RC_DIAMETER_INVALID_MESSAGE_LENGTH,
          header,
          "Parsed message length is higher than packet size");
    }

    if ((flags & ProtocolDefinitions.HEADER_MASK_RESERVED) != 0) {
      throw DiameterParseException(
          ProtocolDefinitions.RC_DIAMETER_INVALID_HDR_BITS,
          header,
          "Reserved bits must be zero (0)");
    }

    if (((flags & ProtocolDefinitions.HEADER_MASK_BIT_R) != 0) &&
        ((flags & ProtocolDefinitions.HEADER_MASK_BIT_E) != 0)) {
      throw DiameterParseException(
          ProtocolDefinitions.RC_DIAMETER_INVALID_HDR_BITS,
          header,
          "Error bit is set for a Request message");
    }

    return header;
  }

  int getMessageLength() => header.getMessageLength();

  static void decodePacketForAVPs(ByteData buffer, DiameterMessage message) {
    while (buffer.offsetInBytes < message.getMessageLength()) {
      int avpCode = BufferUtilities.get4BytesAsUnsigned32(buffer);
      int flags = buffer.getUint8(0);

      if ((flags & ProtocolDefinitions.AVP_MASK_RESERVED) != 0) {
        throw DiameterParseException(
            ProtocolDefinitions.RC_DIAMETER_INVALID_AVP_BITS,
            message,
            "Invalid AVP bits for AVP = $avpCode with flags = $flags");
      }

      int avpLength = BufferUtilities.get3BytesFromBuffer(buffer);
      int vendorId;
      int dataLength;
      if ((flags & ProtocolDefinitions.AVP_MASK_BIT_V) != 0) {
        vendorId = BufferUtilities.get4BytesAsUnsigned32(buffer);
        dataLength = avpLength - ProtocolDefinitions.AVP_HDR_LEN_WITH_VENDOR;
      } else {
        vendorId = 0;
        dataLength = avpLength - ProtocolDefinitions.AVP_HDR_LEN_WITHOUT_VENDOR;
      }

      if ((dataLength > avpLength) ||
          (buffer.lengthInBytes - buffer.offsetInBytes) < dataLength) {
        int len = (buffer.lengthInBytes - buffer.offsetInBytes) < dataLength
            ? buffer.lengthInBytes - buffer.offsetInBytes
            : avpLength;
        throw DiameterParseException(
            ProtocolDefinitions.RC_DIAMETER_INVALID_AVP_LENGTH,
            message,
            "Not enough AVP data remaining");
      }

      int padding = BufferUtilities.calculatePadding(avpLength);
      AVPFactory factory = AVPFactory.getAVPFactory(avpCode, vendorId);
      DiameterAVP avp = factory.createAVP(avpCode, flags, vendorId);

      avp.decodeData(buffer, dataLength);
      buffer.offsetInBytes += padding;

      message.avpList.add(avp);
    }
  }

  void addAVPIntoList(DiameterAVP avp) {
    avpList.add(avp);
    header.addLengthToMessage(avp.getAvpLength());
    header.addLengthToMessage(
        BufferUtilities.calculatePadding(avp.getAvpLength()));
  }

  void addAVP(DiameterAVP avp) => addAVPIntoList(avp);

  void addAVPFromDictionary(int avpCode, int vendorId, String data) {
    DiameterAVP avp = AVPFactory.createAVPFromDictionary(avpCode, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addAVPFromDictionary(int avpCode, int vendorId, List<int> data) {
    DiameterAVP avp = AVPFactory.createAVPFromDictionary(avpCode, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addFloat32AVP(int avpCode, int flags, int vendorId, double data) {
    Float32AVP avp = Float32AVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addFloat64AVP(int avpCode, int flags, int vendorId, double data) {
    Float64AVP avp = Float64AVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addGroupedAVP(
      int avpCode, int flags, int vendorId, List<DiameterAVP> avpList) {
    GroupedAVP avp = GroupedAVP(avpCode, flags, vendorId);
    avp.setList(avpList);
    addAVPIntoList(avp);
  }

  void addInteger32AVP(int avpCode, int flags, int vendorId, int data) {
    Integer32AVP avp = Integer32AVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addInteger64AVP(int avpCode, int flags, int vendorId, int data) {
    Integer64AVP avp = Integer64AVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addOctetStringAVP(int avpCode, int flags, int vendorId, String data) {
    OctetStringAVP avp = OctetStringAVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addUnsigned32AVP(int avpCode, int flags, int vendorId, int data) {
    Unsigned32AVP avp = Unsigned32AVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addUnsigned64AVP(int avpCode, int flags, int vendorId, int data) {
    Unsigned64AVP avp = Unsigned64AVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void addAddressAVP(int avpCode, int flags, int vendorId, InetAddress data) {
    AddressAVP avp = AddressAVP(avpCode, flags, vendorId);
    avp.setData(data);
    addAVPIntoList(avp);
  }

  void printContent(StringBuffer sb) {
    sb.write(
        "Message Command Code: ${header.commandCode}, Application Id: ${header.applicationId}, "
        "HopByHop Id: ${header.hopByHopId}, EndToEnd Id: ${header.endToEndId}\n");
    for (var avp in avpList) {
      sb.write("   ");
      avp.printContent(sb);
      sb.write("\n");
    }
  }
}
