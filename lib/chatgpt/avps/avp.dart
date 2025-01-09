import 'dart:typed_data';
import 'dart:convert';

import '../packunpack.dart';

class DiameterAVP {
  final int code;
  final int flags;
  int length;
  final int vendorId;
  Uint8List _value;

  final String name;

  DiameterAVP({
    required this.code,
    required this.flags,
    required this.length,
    required this.vendorId,
    required Uint8List value,
    this.name = 'DiameterAVP', // Default value
  }) : _value = value;

  // Getter for `value`
  Uint8List get value => _value;

  // Setter for `value`
  set value(Uint8List newValue) {
    _value = newValue;
    length = _value.length + 8; // Update length accordingly
  }

  /// Encode the Diameter AVP into bytes using PackUnpack methods
  Uint8List encode() {
    final buffer =
        List<int>.filled(8 + _value.length + (flags & 0x80 != 0 ? 4 : 0), 0);

    // Pack AVP fields
    PackUnpack.pack32(buffer, 0, code);
    buffer[4] = flags;
    PackUnpack.pack8(buffer, 5, (length >> 16) & 0xFF);
    PackUnpack.pack8(buffer, 6, (length >> 8) & 0xFF);
    PackUnpack.pack8(buffer, 7, length & 0xFF);

    int offset = 8;
    if (flags & 0x80 != 0) {
      PackUnpack.pack32(buffer, offset, vendorId);
      offset += 4;
    }

    // Pack value
    buffer.setRange(offset, offset + _value.length, _value);

    // Pad to 4-byte alignment if necessary
    final paddingLength = (4 - (length % 4)) % 4;
    return Uint8List.fromList(
      buffer + List<int>.filled(paddingLength, 0),
    );
  }

  // The `asPacked` method: serializes the AVP into a packed format (byte stream).
  Uint8List asPacked(Packer packer) {
    final packedData = encode();
    packer.pack(packedData); // Use the Packer class to handle the data
    return packedData;
  }

  // Factory to create a copy from another AVP
  factory DiameterAVP.fromAVP(DiameterAVP avp) {
    return DiameterAVP(
      code: avp.code,
      flags: avp.flags,
      length: avp.length,
      vendorId: avp.vendorId,
      value: avp._value,
    );
  }

  static DiameterAVP decode(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Data too short to decode Diameter AVP.');
    }

    // AVP Code (4 bytes)
    final code = PackUnpack.unpack32(data, 0);

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
      vendorId = PackUnpack.unpack32(data, 8);
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

  // Convenience method to encode string values
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

  // Convenience method to encode integer values
  static DiameterAVP integerAVP(int code, int value,
      {int flags = 0, int vendorId = 0}) {
    final valueBytes = List<int>.filled(4, 0);
    PackUnpack.pack32(valueBytes, 0, value);
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

  // Convenience method to encode grouped AVPs
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

  bool get isMandatory => (flags & 0x40) != 0;
  bool get isPrivate => (flags & 0x20) != 0;
  bool get isVendor => (flags & 0x80) != 0;

  @override
  String toString() {
    return "{code: $code, flags: $flags, length: $length, vendorId: $vendorId, value: $_value}";
  }
}

// A basic Packer class to manage the packing process (dummy implementation)
class Packer {
  final List<int> _buffer = [];

  void pack(Uint8List data) {
    _buffer.addAll(data);
  }

  Uint8List getBuffer() {
    return Uint8List.fromList(_buffer);
  }
}

void main() {
  // Example usage of the DiameterAVP class with PackUnpack methods
  final avp = DiameterAVP.stringAVP(1, "Test AVP");

  // Packing the AVP using the Packer
  final packer = Packer();
  avp.asPacked(packer);

  print("Packed AVP: ${packer.getBuffer()}");
}
