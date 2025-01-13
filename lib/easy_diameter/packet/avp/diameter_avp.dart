import 'dart:typed_data';

class DiameterParseException implements Exception {
  final int code;
  final String message;

  DiameterParseException(this.code, this.message);

  @override
  String toString() => 'DiameterParseException: $message (Code: $code)';
}

abstract class DiameterAVP {
  static const int AVP_MASK_BIT_V = 0x80;
  static const int AVP_MASK_BIT_M = 0x40;
  static const int AVP_MASK_BIT_P = 0x20;
  static const int AVP_HDR_LEN_WITH_VENDOR = 12;
  static const int AVP_HDR_LEN_WITHOUT_VENDOR = 8;

  // Header part of the AVP
  late int code;
  late int flags;
  late int avpLength;
  late int vendorId;

  int dataLength = 0;
  late List<int> byteData;

  String? name;

  DiameterAVP(this.code, this.flags, this.vendorId) {
    avpLength = findAVPHeaderLength(flags);
  }

  DiameterAVP.fromDictionaryData(AVPDictionaryData dictData) {
    code = dictData.code;
    flags = dictData.flags;
    vendorId = dictData.vendorId;
    avpLength = findAVPHeaderLength(flags);
  }

  //void setData(dynamic data);

  void setDataBytes(List<int> data) {
    byteData = data;
    dataLength = data.length;
    avpLength += dataLength;
  }

  void encode(ByteData buffer) {
    set4BytesToBuffer(buffer, code);
    buffer.setUint8(buffer.lengthInBytes, flags);
    set3BytesToBuffer(buffer, avpLength);
    if ((flags & AVP_MASK_BIT_V) != 0) {
      set4BytesToBuffer(buffer, vendorId);
    }
    encodeData(buffer);
    buffer.setUint8(buffer.lengthInBytes, calculatePadding(avpLength));
  }

  void encodeData(ByteData buffer);

  void decodeData(ByteData buffer, int length);

  bool isVendorSpecific() => (flags & AVP_MASK_BIT_V) != 0;

  bool isMandatory() => (flags & AVP_MASK_BIT_M) != 0;

  bool isPrivate() => (flags & AVP_MASK_BIT_P) != 0;

  DiameterAVP setVBit(bool isVendor) {
    if (isVendor) {
      flags |= AVP_MASK_BIT_V;
    } else {
      flags &= ~AVP_MASK_BIT_V;
    }
    return this;
  }

  DiameterAVP setMBit(bool isMandatory) {
    if (isMandatory) {
      flags |= AVP_MASK_BIT_M;
    } else {
      flags &= ~AVP_MASK_BIT_M;
    }
    return this;
  }

  DiameterAVP setPBit(bool isPrivate) {
    if (isPrivate) {
      flags |= AVP_MASK_BIT_P;
    } else {
      flags &= ~AVP_MASK_BIT_P;
    }
    return this;
  }

  void addDataLength(int length) {
    dataLength = length;
    avpLength += dataLength;
  }

  int getAvpLength() => avpLength;

  String? getName() => name;

  void setName(String name) {
    this.name = name;
  }

  // void printContent(StringBuffer sb) {
  //   if (name == null) {
  //     // You should define `AVPDictionary.getDictionaryData` as per your use case
  //     AVPDictionaryData dictData = AVPDictionary.getDictionaryData(code, vendorId);
  //     name = dictData.name;
  //   }
  //   sb.write('$name AVP($code): ');
  //   printData(sb);
  // }

  //void printData(StringBuffer sb);

  // Helper methods for encoding and decoding
  int findAVPHeaderLength(int flags) {
    // Implement header length calculation based on flags
    return (flags & AVP_MASK_BIT_V) != 0
        ? AVP_HDR_LEN_WITH_VENDOR
        : AVP_HDR_LEN_WITHOUT_VENDOR;
  }

  void set4BytesToBuffer(ByteData buffer, int value) {
    buffer.setInt32(buffer.lengthInBytes, value, Endian.big);
  }

  void set3BytesToBuffer(ByteData buffer, int value) {
    buffer.setUint8(buffer.lengthInBytes, (value >> 16) & 0xFF);
    buffer.setUint8(buffer.lengthInBytes + 1, (value >> 8) & 0xFF);
    buffer.setUint8(buffer.lengthInBytes + 2, value & 0xFF);
  }

  int calculatePadding(int length) {
    return (4 - (length % 4)) % 4;
  }
}

class AVPDictionaryData {
  final int code;
  final int flags;
  final int vendorId;
  final String name;

  AVPDictionaryData({
    required this.code,
    required this.flags,
    required this.vendorId,
    required this.name,
  });

  // For your use case, implement how the data is retrieved for a dictionary entry
  static AVPDictionaryData getDictionaryData(int code, int vendorId) {
    // Replace this logic with the actual implementation
    return AVPDictionaryData(
        code: code, flags: 0, vendorId: vendorId, name: 'Sample AVP');
  }
}
