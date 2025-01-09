import 'dart:convert';
import 'dart:typed_data';

class DiameterAVP {
  final int code;
  final int flags;
  int length;
  final int vendorId;
  Uint8List _value;

  DiameterAVP({
    required this.code,
    required this.flags,
    required this.length,
    required this.vendorId,
    required Uint8List value,
  }) : _value = value;

  // Getter for `value`
  Uint8List get value => _value;

  // Setter for `value`
  set value(Uint8List newValue) {
    _value = newValue;
    length = _value.length + 8; // Update length accordingly
  }

  /// Encode the Diameter AVP into bytes
  Uint8List encode() {
    final buffer = ByteData(8 + _value.length + (flags & 0x80 != 0 ? 4 : 0));
    buffer.setUint32(0, code, Endian.big);
    buffer.setUint8(4, flags);
    buffer.setUint8(5, (length >> 16) & 0xFF);
    buffer.setUint8(6, (length >> 8) & 0xFF);
    buffer.setUint8(7, length & 0xFF);

    int offset = 8;
    if (flags & 0x80 != 0) {
      buffer.setUint32(offset, vendorId, Endian.big);
      offset += 4;
    }

    buffer.buffer
        .asUint8List()
        .setRange(offset, offset + _value.length, _value);

    // Pad to 4-byte alignment if necessary
    final paddingLength = (4 - (length % 4)) % 4;
    return Uint8List.fromList(
      buffer.buffer.asUint8List(0, 8 + _value.length) +
          List<int>.filled(paddingLength, 0),
    );
  }

  /// Decode a Diameter AVP from bytes
  // static DiameterAVP decode(Uint8List data) {
  //   if (data.length < 8) {
  //     throw FormatException('Data too short to decode Diameter AVP.');
  //   }

  //   // Extract AVP header information
  //   final code = (data[0] << 16) | (data[1] << 8) | data[2]; // 3-byte code
  //   final flags = data[3]; // 1-byte flags
  //   final length = (data[4] << 16) | (data[5] << 8) | data[6]; // 3-byte length
  //   final vendorId = (data[7] << 24) |
  //       (data[8] << 16) |
  //       (data[9] << 8) |
  //       data[10]; // 4-byte vendor ID if flag is set

  //   if (data.length < length) {
  //     throw FormatException(
  //         'AVP length mismatch. Data is too short. length: ${data.length} < $length');
  //   }

  //   // Extract value (it starts after the first 10 bytes if Vendor ID is included)
  //   int valueOffset = 10; // By default, Vendor ID is included
  //   if ((flags & 0x80) == 0) {
  //     valueOffset = 8; // No Vendor ID in the AVP
  //   }

  //   final value = data.sublist(valueOffset, length);

  //   return DiameterAVP(
  //     code: code,
  //     flags: flags,
  //     length: length,
  //     vendorId: vendorId,
  //     value: value,
  //   );
  // }

  // Factory to create a copy from another AVP
  factory DiameterAVP.fromAVP(DiameterAVP avp) {
    return DiameterAVP(
        code: avp.code,
        flags: avp.flags,
        length: avp.length,
        value: avp._value,
        vendorId: avp.vendorId);
  }

  static DiameterAVP decode(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Data too short to decode Diameter AVP.');
    }

    // AVP Code (4 bytes)
    final code = ByteData.sublistView(data, 0, 4).getUint32(0, Endian.big);

    // Flags (1 byte)
    final flags = data[4];

    // Length (3 bytes)
    final length = ((data[5] << 16) | (data[6] << 8) | data[7]);

    if (length > data.length) {
      throw FormatException(
          'AVP length mismatch. Expected $length, got ${data.length}');
    }

    // Vendor ID (4 bytes) if the 'V' flag is set
    int vendorId = 0;
    int valueOffset = 8; // Start after the mandatory fields
    if ((flags & 0x80) != 0) {
      // 'V' flag indicates Vendor ID is present
      if (data.length < 12) {
        throw FormatException('Data too short for Vendor-Specific AVP.');
      }
      vendorId = ByteData.sublistView(data, 8, 12).getUint32(0, Endian.big);
      valueOffset += 4;
    }

    // Value (rest of the data until length, excluding padding)
    final valueLength = length - valueOffset;
    if (valueLength < 0 || valueOffset + valueLength > data.length) {
      throw FormatException('Invalid AVP length or value offset.');
    }
    final value = data.sublist(valueOffset, valueOffset + valueLength);

    return DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
      value: value,
    );
  }

  /// Convenience method to encode string values
  static DiameterAVP stringAVP(int code, String value,
      {int flags = 0, int vendorId = 0}) {
    final encodedValue = Uint8List.fromList(utf8.encode(value));
    final length = 8 + encodedValue.length; // 8 bytes for header + value length
    final avp = DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
      value: encodedValue,
    );
    return avp;
  }

  /// Convenience method to encode integer values
  static DiameterAVP integerAVP(int code, int value,
      {int flags = 0, int vendorId = 0}) {
    final valueBytes = ByteData(4)..setUint32(0, value, Endian.big);
    final length =
        8 + valueBytes.buffer.asUint8List().length; // Header + value length
    final encodedValue = valueBytes.buffer.asUint8List();

    final avp = DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
      value: encodedValue,
    );

    return avp;
  }

  /// Convenience method to encode grouped AVPs
  static DiameterAVP groupedAVP(int code, List<DiameterAVP> avps,
      {int flags = 0, int vendorId = 0}) {
    final valueBytes = avps.expand((avp) => avp.encode()).toList();
    final length = 8 + valueBytes.length; // Header + value length

    final avp = DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
      value: Uint8List.fromList(valueBytes),
    );

    return avp;
  }

  /// Convenience method to encode a Redirect AVP
  static DiameterAVP redirectAVP(
      int code, String redirectAddress, int redirectPort,
      {int flags = 0, int vendorId = 0}) {
    // Encode the redirect address and port as a string
    final redirectValue = '$redirectAddress:$redirectPort';
    final encodedValue = Uint8List.fromList(utf8.encode(redirectValue));
    final length = 8 + encodedValue.length; // 8 bytes for header + value length

    // Create the Redirect AVP
    final avp = DiameterAVP(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
      value: encodedValue,
    );

    return avp;
  }

  //rfc 4006
  // Convenience method for CC-Request-Type AVP
  static DiameterAVP ccRequestTypeAvp(int value) {
    return DiameterAVP.integerAVP(416, value); // CC-Request-Type AVP code
  }

  // Convenience method for CC-Request-Number AVP
  static DiameterAVP ccRequestNumberAvp(int value) {
    return DiameterAVP.integerAVP(415, value); // CC-Request-Number AVP code
  }

  // Convenience method for Requested-Action AVP
  static DiameterAVP requestedActionAvp(int value) {
    return DiameterAVP.integerAVP(428, value); // Requested-Action AVP code
  }

  // Convenience method for Balance-Amount AVP
  static DiameterAVP balanceAmountAvp(int value) {
    return DiameterAVP.integerAVP(432, value); // Balance-Amount AVP code
  }

  bool get isMandatory => (flags & 0x40) != 0;
  bool get isPrivate => (flags & 0x20) != 0;
  bool get isVendor => (flags & 0x80) != 0;

  @override
  String toString() {
    // TODO: implement toString
    return "{code: $code, flags: $flags, length: $length, vendoID: $vendorId, value: $_value}";
  }
}

// Main function to demonstrate encoding and decoding AVPs
// void main() {
//   // Step 1: Create individual AVPs
//   final stringAVP = DiameterAVP.stringAVP(1, "Example String AVP");
//   final integerAVP = DiameterAVP.integerAVP(2, 12345);
//   final groupedAVP = DiameterAVP.groupedAVP(3, [stringAVP, integerAVP]);

//   // Step 2: Encode AVPs
//   final encodedStringAVP = stringAVP.encode();
//   final encodedIntegerAVP = integerAVP.encode();
//   final encodedGroupedAVP = groupedAVP.encode();

//   print("Encoded String AVP: $encodedStringAVP");
//   print("Encoded Integer AVP: $encodedIntegerAVP");
//   print("Encoded Grouped AVP: $encodedGroupedAVP");

//   // Step 3: Decode AVPs
//   final decodedStringAVP =
//       DiameterAVP.decode(Uint8List.fromList(encodedStringAVP));
//   final decodedIntegerAVP =
//       DiameterAVP.decode(Uint8List.fromList(encodedIntegerAVP));
//   final decodedGroupedAVP =
//       DiameterAVP.decode(Uint8List.fromList(encodedGroupedAVP));

//   print("\nDecoded String AVP:");
//   print("  Code: ${decodedStringAVP.code}");
//   print("  Value: ${utf8.decode(decodedStringAVP.value)}");

//   print("\nDecoded Integer AVP:");
//   print("  Code: ${decodedIntegerAVP.code}");
//   final intValue =
//       ByteData.sublistView(decodedIntegerAVP.value).getUint32(0, Endian.big);
//   print("  Value: $intValue");

//   print("\nDecoded Grouped AVP:");
//   print("  Code: ${decodedGroupedAVP.code}");
//   print("  Contains ${decodedGroupedAVP.value.length} bytes of data");

//   // Inspecting AVPs inside the Grouped AVP
//   print("\nInspecting AVPs in the Grouped AVP:");
//   final innerAVPs = _decodeGroupedAVP(decodedGroupedAVP);
//   for (int i = 0; i < innerAVPs.length; i++) {
//     final avp = innerAVPs[i];
//     print(
//         "  Inner AVP $i - Code: ${avp.code}, Value Length: ${avp.value.length}");
//     if (avp.code == 1) {
//       print("    Value (String): ${utf8.decode(avp.value)}");
//     } else if (avp.code == 2) {
//       final innerIntValue =
//           ByteData.sublistView(avp.value).getUint32(0, Endian.big);
//       print("    Value (Integer): $innerIntValue");
//     }
//   }
// }

// Helper function to decode grouped AVPs
List<DiameterAVP> _decodeGroupedAVP(DiameterAVP groupedAVP) {
  final avps = <DiameterAVP>[];
  int offset = 0;

  // Iterate through the grouped AVP's value, decoding each AVP
  while (offset < groupedAVP._value.length) {
    try {
      // Slice the value data starting from the current offset
      final remainingBytes = groupedAVP._value.sublist(offset);

      // Decode the AVP from the remaining bytes
      final avp = DiameterAVP.decode(Uint8List.fromList(remainingBytes));
      avps.add(avp);

      // Move the offset forward by the length of the decoded AVP
      offset += avp.length;
    } catch (e) {
      print('Error decoding AVP at offset $offset: $e');
      break;
    }
  }

  return avps;
}

void main() {}
