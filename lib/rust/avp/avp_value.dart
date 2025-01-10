import 'dart:convert';
import 'dart:typed_data';

class AvpFlags {
  final bool vendor;
  final bool mandatory;
  final bool private;

  AvpFlags(
      {required this.vendor, required this.mandatory, required this.private});
}

class AvpHeader {
  final int code;
  final AvpFlags flags;
  final int length;
  final int? vendorId;

  AvpHeader({
    required this.code,
    required this.flags,
    required this.length,
    this.vendorId,
  });

  // Decode from a list of bytes
  static AvpHeader decodeFrom(Uint8List data) {
    if (data.length < 8) {
      throw FormatException('Insufficient data for AVP header');
    }

    final code = _toInt32(data.sublist(0, 4));
    final flags = AvpFlags(
      vendor: (data[4] & 0x80) != 0,
      mandatory: (data[4] & 0x40) != 0,
      private: (data[4] & 0x20) != 0,
    );
    final length = _toInt32(data.sublist(5, 8)) & 0x00FFFFFF;
    int? vendorId;

    if ((data[4] & 0x80) != 0) {
      vendorId = _toInt32(data.sublist(8, 12));
    }

    return AvpHeader(
      code: code,
      flags: flags,
      length: length,
      vendorId: vendorId,
    );
  }

  // Encode to a list of bytes
  Uint8List encodeTo() {
    final buffer = ByteData(8);
    buffer.setInt32(0, code, Endian.big);

    int flagsByte = 0;
    if (flags.vendor) flagsByte |= 0x80;
    if (flags.mandatory) flagsByte |= 0x40;
    if (flags.private) flagsByte |= 0x20;
    buffer.setUint8(4, flagsByte);

    buffer.setInt32(5, length, Endian.big);

    final encodedHeader = buffer.buffer.asUint8List();

    final result = Uint8List.fromList(encodedHeader);
    if (flags.vendor && vendorId != null) {
      final vendorIdBytes = _toBytes(vendorId!);
      return Uint8List.fromList([...result, ...vendorIdBytes]);
    }
    return result;
  }

  // Helper functions
  static int _toInt32(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  static List<int> _toBytes(int value, {int lengthSize = 4}) {
    return List<int>.generate(
        lengthSize, (i) => (value >> (8 * (lengthSize - 1 - i)) & 0xFF));
  }
}

class Avp {
  final AvpHeader header;
  final AvpValue value;
  final int padding;
  final Dictionary dict;

  Avp({
    required this.header,
    required this.value,
    required this.padding,
    required this.dict,
  });

  static Future<Avp> fromName(
      String avpName, AvpValue value, Dictionary dict) async {
    final avpDef = await dict.getAvpByName(avpName);
    if (avpDef == null) throw Exception('Unknown AVP Name: $avpName');

    final flags = avpDef.mandatory ? 0x40 : 0;
    return Avp.newInstance(avpDef.code, avpDef.vendorId, flags, value, dict);
  }

  // Create a new instance of Avp
  static Avp newInstance(
      int code, int? vendorId, int flags, AvpValue value, Dictionary dict) {
    final header = AvpHeader(
      code: code,
      flags: AvpFlags(
        vendor: vendorId != null,
        mandatory: (flags & 0x40) != 0,
        private: (flags & 0x20) != 0,
      ),
      length: (vendorId != null ? 12 : 8) + value.length(),
      vendorId: vendorId,
    );
    final padding = Avp.padTo32Bits(value.length());
    return Avp(
      header: header,
      value: value,
      padding: padding,
      dict: dict,
    );
  }

  static int padTo32Bits(int length) {
    return (4 - (length % 4)) % 4;
  }

  // Encode to a list of bytes
  Uint8List encodeTo() {
    final encodedHeader = header.encodeTo();
    final encodedValue = value.encodeTo();

    final result = Uint8List.fromList([...encodedHeader, ...encodedValue]);

    // Add padding
    for (int i = 0; i < padding; i++) {
      result.add(0);
    }

    return result;
  }
}

abstract class AvpValue {
  int length();
  Uint8List encodeTo();
}

class Address implements AvpValue {
  @override
  int length() {
    return 4; // Example length for Address
  }

  @override
  Uint8List encodeTo() {
    // Example encoding logic for Address
    return Uint8List(4);
  }
}

class IPv4 implements AvpValue {
  @override
  int length() {
    return 4; // Example length for IPv4
  }

  @override
  Uint8List encodeTo() {
    // Example encoding logic for IPv4
    return Uint8List(4);
  }
}

class IPv6 implements AvpValue {
  @override
  int length() {
    return 16; // Example length for IPv6
  }

  @override
  Uint8List encodeTo() {
    // Example encoding logic for IPv6
    return Uint8List(16);
  }
}

// Similar classes for other AvpValue types

class Dictionary {
  Future<AvpDef?> getAvpByName(String name) async {
    // Example implementation to get AVP definition by name
    return AvpDef(code: 123, vendorId: null, mandatory: true);
  }
}

class AvpDef {
  final int code;
  final int? vendorId;
  final bool mandatory;

  AvpDef({
    required this.code,
    this.vendorId,
    required this.mandatory,
  });
}

void main() async {
  // Example usage
  // final dict = Dictionary();
  // final avpValue = Address();
  // final avp = await Avp.fromName('Address', avpValue, dict);

  // final encodedAvp = avp.encodeTo();
  // print(encodedAvp);
  testDecodeFromBytes();
}

void testDecodeFromBytes() {
  final avpBytes = Uint8List.fromList([
    0x00, 0x00, 0x01, 0xCD, // Code
    0x40, // Flags
    0x00, 0x00, 0x16, // Length
    0x33, 0x32, 0x32, 0x35, // Value: "32251@3gpp.org"
    0x31, 0x40, 0x33, 0x67,
    0x70, 0x70, 0x2E, 0x6F,
    0x72, 0x67, 0x00, 0x00 // Padding
  ]);
  // final a = Avp.decode(avpBytes);
  final a = AvpHeader.decodeFrom(avpBytes);

  if (a.code != 461) {
    throw "Expected: 461. Got: ${a.code}";
  }

  // if (a.isMandatory != true) {
  //   throw "Expected isMandatory: true. Got: ${a.code}";
  // }
  // if (a.isPrivate != false) {
  //   throw "Expected isPrivate: false. Got: ${a.isPrivate}";
  // }
  // if (a.isVendor != false) {
  //   throw "Expected isVendor: false. Got: ${a.isVendor}";
  // }
  // if (a.length != 22) {
  //   throw "Expected length: 22. Got: ${a.length}";
  // }
  // if (utf8.decode(a.value) != "32251@3gpp.org") {
  //   throw "Expected value: true. Got: ${a.value}";
  // }
  print("avp: $a");
}
