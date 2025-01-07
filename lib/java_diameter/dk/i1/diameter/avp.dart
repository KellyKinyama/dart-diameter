import 'dart:typed_data';

/// A Diameter AVP as per RFC3588.
/// Consists of a code, some flags, an optional vendor ID, and a payload.
class AVP {
  late Uint8List payload;

  /// The AVP code
  int code = 0;

  /// The flags except the vendor flag
  int _flags = 0;

  /// The vendor ID. Assigning directly updates the vendor flag bit
  int vendorId = 0;

  static const int avpFlagVendor = 0x80;
  static const int avpFlagMandatory = 0x40;
  static const int avpFlagPrivate = 0x20;

  /// Default constructor
  AVP();

  /// Copy constructor (deep copy)
  AVP.copy(AVP a)
      : payload = Uint8List.fromList(a.payload),
        code = a.code,
        _flags = a._flags,
        vendorId = a.vendorId;

  /// Create AVP with code and payload
  AVP.withPayload(this.code, Uint8List payload)
      : payload = Uint8List.fromList(payload);

  /// Create AVP with code, vendor ID, and payload
  AVP.withVendor(this.code, this.vendorId, Uint8List payload)
      : payload = Uint8List.fromList(payload);

  static int decodeSize(Uint8List b, int offset, int bytes) {
    if (bytes < 8) return 0; // garbage

    final flagsAndLength = _unpack32(b, offset + 4);
    final flags = (flagsAndLength >> 24) & 0xff;
    final length = flagsAndLength & 0x00ffffff;
    final paddedLength = (length + 3) & ~3;

    if ((flags & avpFlagVendor) != 0) {
      if (length < 12) return 0; // garbage
    } else {
      if (length < 8) return 0; // garbage
    }

    return paddedLength;
  }

  bool decode(Uint8List b, int offset, int bytes) {
    if (bytes < 8) return false;

    int i = 0;
    code = _unpack32(b, offset + i);
    i += 4;

    final flagsAndLength = _unpack32(b, offset + i);
    i += 4;

    _flags = (flagsAndLength >> 24) & 0xff;
    int length = flagsAndLength & 0x00ffffff;
    final paddedLength = (length + 3) & ~3;

    if (bytes != paddedLength) return false;

    length -= 8;
    if ((_flags & avpFlagVendor) != 0) {
      if (length < 4) return false;
      vendorId = _unpack32(b, offset + i);
      i += 4;
      length -= 4;
    } else {
      vendorId = 0;
    }

    setPayload(b.sublist(offset + i, offset + i + length));
    return true;
  }

  int encodeSize() {
    int size = 8; // code (4 bytes) + flags and length (4 bytes)
    if (vendorId != 0) size += 4;
    size += (payload.length + 3) & ~3;
    return size;
  }

  int encode(Uint8List b, int offset) {
    int size = encodeSize();
    int flags = _flags;

    if (vendorId != 0) {
      flags |= avpFlagVendor;
    } else {
      flags &= ~avpFlagVendor;
    }

    int i = offset;
    _pack32(b, i, code);
    i += 4;
    _pack32(b, i, size | (flags << 24));
    i += 4;

    if (vendorId != 0) {
      _pack32(b, i, vendorId);
      i += 4;
    }

    b.setRange(i, i + payload.length, payload);
    return size;
  }

  Uint8List encodeToBytes() {
    final b = Uint8List(encodeSize());
    encode(b, 0);
    return b;
  }

  Uint8List queryPayload() => Uint8List.fromList(payload);

  int queryPayloadSize() => payload.length;

  void setPayload(Uint8List newPayload) {
    payload = Uint8List.fromList(newPayload);
  }

  bool isVendorSpecific() => vendorId != 0;

  bool isMandatory() => (_flags & avpFlagMandatory) != 0;

  bool isPrivate() => (_flags & avpFlagPrivate) != 0;

  void setMandatory(bool value) {
    if (value) {
      _flags |= avpFlagMandatory;
    } else {
      _flags &= ~avpFlagMandatory;
    }
  }

  void setPrivate(bool value) {
    if (value) {
      _flags |= avpFlagPrivate;
    } else {
      _flags &= ~avpFlagPrivate;
    }
  }

  AVP setM() {
    _flags |= avpFlagMandatory;
    return this;
  }

  void inlineShallowReplace(AVP a) {
    payload = Uint8List.fromList(a.payload);
    code = a.code;
    _flags = a._flags;
    vendorId = a.vendorId;
  }

  static int _unpack32(Uint8List b, int offset) {
    return (b[offset] << 24) |
        (b[offset + 1] << 16) |
        (b[offset + 2] << 8) |
        b[offset + 3];
  }

  static void _pack32(Uint8List b, int offset, int value) {
    b[offset] = (value >> 24) & 0xff;
    b[offset + 1] = (value >> 16) & 0xff;
    b[offset + 2] = (value >> 8) & 0xff;
    b[offset + 3] = value & 0xff;
  }
}
