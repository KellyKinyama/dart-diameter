import 'dart:convert';
import 'dart:typed_data';

class Avp {
  static const int avpFlagVendor = 0x80;
  static const int avpFlagMandatory = 0x40;
  static const int avpFlagPrivate = 0x20;

  int _vendorId = 0;
  int code;
  int flags;
  late List<int> payload;
  String name = 'Unknown';

  Avp({
    this.code = 0,
    int vendorId = 0,
    List<int> payload = const [],
    this.flags = 0,
  }) {
    this.vendorId = vendorId;
  }

  @override
  String toString() {
    var ownValue = value;
    var fmtVal = '';
    var vndVal = '';
    if (ownValue is! List) {
      fmtVal = ', Val: $ownValue';
    }
    if (vendorId != 0) {
      vndVal = ', Vnd: $vendorId';
    }

    return '$name <Code: 0x${code.toRadixString(16).padLeft(2, '0')}, Flags: 0x${flags.toRadixString(16).padLeft(2, '0')} (${_flags().join('')}), Length: ${length}$vndVal$fmtVal>';
  }

  List<String> _flags() {
    final checked = {
      "V": isVendor,
      "M": isMandatory,
      "P": isPrivate,
    };
    return checked.entries
        .map((entry) => entry.value ? entry.key : '-')
        .toList();
  }

  List<int> asBytes() {
    final packer = Packer();
    return asPacked(packer).getBuffer();
  }

  Packer asPacked(Packer packer) {
    int flags = this.flags;
    packer.packUint(code);
    packer.packUint(length | (flags << 24));
    if (vendorId != 0) {
      packer.packUint(vendorId);
    }
    int paddedPayloadLength = (payload.length + 3) & ~3;
    packer.packFopaque(paddedPayloadLength, payload);
    return packer;
  }

  static Avp fromAvp(Avp anotherAvp) {
    return Avp.fromBytes(anotherAvp.asBytes());
  }

  static Avp fromBytes(List<int> avpData) {
    try {
      return Avp.fromUnpacker(Unpacker(avpData));
    } catch (e) {
      throw AvpDecodeError("Not possible to create AVP from byte input: $e");
    }
  }

  static Avp fromUnpacker(Unpacker unpacker) {
    int avpCode = unpacker.unpackUint();
    int flagsLen = unpacker.unpackUint();
    int avpFlags = flagsLen >> 24;
    int avpLength = flagsLen & 0x00ffffff;
    avpLength -= 8;

    int avpVendorId = 0;
    if (avpFlags & Avp.avpFlagVendor != 0) {
      avpVendorId = unpacker.unpackUint();
      avpLength -= 4;
    }

    List<int> avpPayload = [];
    if (avpLength > 0) {
      avpPayload = unpacker.unpackFopaque(avpLength);
    }
    String? avpName;

    // Simulating AVP_DICTIONARY lookup
    Type avpType;
    avpType = Avp;
    avpName = 'Unknown'; // Replace this with actual dictionary logic

    final avp = avpType(avpCode, avpVendorId, avpPayload, avpFlags);
    if (avpName != null) avp.name = avpName;

    return avp;
  }

  static Avp newAvp({
    required int avpCode,
    int vendorId = 0,
    dynamic value,
    bool? isMandatory,
    bool? isPrivate,
  }) {
    // Simulate AVP_DICTIONARY lookup
    var entry = {
      'type': Avp,
      'name': 'Unknown'
    }; // Replace with actual dictionary logic
    Type avpType = entry['type'];
    var avp = avpType(avpCode, vendorId: vendorId);

    if (value != null) {
      avp.value = value;
    }
    if (isMandatory != null) avp.isMandatory = isMandatory;
    if (isPrivate != null) avp.isPrivate = isPrivate;

    return avp;
  }

  bool get isVendor => vendorId != 0;

  bool get isMandatory => (flags & avpFlagMandatory) != 0;

  set isMandatory(bool value) {
    if (value) {
      flags |= avpFlagMandatory;
    } else {
      flags &= ~avpFlagMandatory;
    }
  }

  bool get isPrivate => (flags & avpFlagPrivate) != 0;

  set isPrivate(bool value) {
    if (value) {
      flags |= avpFlagPrivate;
    } else {
      flags &= ~avpFlagPrivate;
    }
  }

  int get length {
    if (payload.isEmpty) {
      return 0;
    }
    int hdrLength = 8;
    if (vendorId != 0) {
      hdrLength += 4;
    }
    return hdrLength + payload.length;
  }

  dynamic get value => payload;

  set value(dynamic newValue) {
    payload = newValue;
  }

  int get vendorId => _vendorId;

  set vendorId(int value) {
    if (value != 0) {
      flags |= avpFlagVendor;
    } else {
      flags &= ~avpFlagVendor;
    }
    _vendorId = value;
  }
}

// A helper class for packing and unpacking AVP data
class Packer {
  final ByteData _buffer = ByteData(0);

  void packUint(int value) {
    // Pack uint logic here
  }

  void packFopaque(int paddedLength, List<int> payload) {
    // Pack Fopaque logic here
  }

  List<int> getBuffer() {
    return _buffer.buffer.asUint8List();
  }
}

// A helper class for unpacking AVP data
class Unpacker {
  Unpacker(List<int> data);

  int unpackUint() {
    // Unpack uint logic here
    return 0;
  }

  List<int> unpackFopaque(int length) {
    // Unpack Fopaque logic here
    return [];
  }
}

class AvpDecodeError implements Exception {
  final String message;
  AvpDecodeError(this.message);
}

void main() {
  // Testing the Avp class
  var avp = Avp(code: 1);
  print(avp);
}
