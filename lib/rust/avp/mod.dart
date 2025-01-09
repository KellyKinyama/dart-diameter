//! # AVP Module
//!
//! This module defines the structure and functionalities related to AVPs in Diameter messages.
//!
//! ## AVP Format
//! The diagram below illustrates the format for an AVP:
//! ```text
//!   0                   1                   2                   3
//!   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
//!  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//!  |                         Command-Code                          |
//!  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//!  |  Flags       |                 AVP Length                     |
//!  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//!  |                         Vendor ID (optional)                  |
//!  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//!  |                             Data                              |
//!  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//!  |                             Data             |    Padding     |
//!  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//!
//!  AVP Flags:
//!    0 1 2 3 4 5 6 7
//!   +-+-+-+-+-+-+-+-+  V(endor), M(andatory), P(rivate)
//!   |V M P r r r r r|  r(eserved)
//!   +-+-+-+-+-+-+-+-+
//! ```
//!

import 'dart:typed_data';

import 'address.dart';
import 'enumerated.dart';
import 'group.dart';
import 'identity.dart';
import 'integer32.dart';
import 'integer64.dart';
import 'time.dart';
import 'unsigned32.dart';
import 'unsigned64.dart';
import 'uri.dart';

enum AvpType {
  ADDRESS,
  ADDRESS_IPv4,
  ADDRESS_IPv6,
  IDENTITY,
  DIAMETERURI,
  ENUMERATED,
  //FLOAT_32(Float32),
  //FLOAT_64(Float64),
  GROUPED,
  INTEGER_32,
  INTEGER_64,
  OCTET_STRING,
  TIME,
  UNSIGNED_32,
  UNSIGNED_32_64,
  UTF8_STRING;
}

enum AvpValue {
  ADDRESS(Address, "Address"),
  ADDRESS_IPv4(IPv4, "AddressIPv4"),
  ADDRESS_IPv6(IPv6, "AddressIPv6"),
  IDENTITY(Identity, "Identity"),
  DIAMETERURI(DiameterURI, "DiameterURI"),
  ENUMERATED(Enumerated, "Enumerated"),
  //FLOAT_32(Float32),
  //FLOAT_64(Float64),
  GROUPED(Grouped, "Grouped"),
  INTEGER_32(Integer32, "Integer32"),
  INTEGER_64(Integer64, "Integer64"),
  OCTET_STRING(OctetString, "OctetString"),
  TIME(Time, "Time"),
  UNSIGNED_32(Unsigned32, "Unsigned32"),
  UNSIGNED_32_64(Unsigned64, "Unsigned64"),
  UTF8_STRING(UTF8String, "UTF8String");

  const AvpValue(this.value, this.name);
  final dynamic value;
  final String name;

  int length() {
    return value.length();
  }

  String getTypeName() {
    return name;
  }

  factory AvpValue.from(dynamic id) {
    return AvpValue.values.firstWhere((test) {
      return test.value.runtimeType == id.runtimeType;
    });
  }
}

class Flags {
  static const V = 0x80;
  static const M = 0x40;
  static const P = 0x20;
}

class AvpHeader {
  final int code; //: u32,
  AvpFlags flags; //: AvpFlags,
  int length;
  int? vendorId;
  AvpHeader(this.code, this.flags, this.length, {this.vendorId});

  static const int avpFlagVendor = 0x80;
  static const int avpFlagMandatory = 0x40;
  static const int avpFlagPrivate = 0x20;

  factory AvpHeader.decodeFrom(Uint8List data, int arrayLegth) {
    if (arrayLegth < 8) throw "error: garbage"; // garbage
    int _flags = 0;
    int offset = 0;
    final code = ByteData.sublistView(data).getUint32(0, Endian.big);
    offset = offset + 4;
    final flags = AvpFlags(
      (data[4] & Flags.V) != 0,
      (data[4] & Flags.M) != 0,
      (data[4] & Flags.P) != 0,
    );

    final flagsAndLength =
        ByteData.sublistView(data).getUint32(offset, Endian.big);
    offset = offset + 4;

    _flags = (flagsAndLength >> 24) & 0xff;
    int length = flagsAndLength & 0x00ffffff;
    final paddedLength = (length + 3) & ~3;

    if (arrayLegth != paddedLength) throw "error: garbage"; // garbage
    int? vendor_id;
    length -= 8;
    if ((_flags & avpFlagVendor) != 0) {
      if (length < 4) throw "error: garbage"; // garbage
      vendor_id = ByteData.sublistView(data).getUint32(offset, Endian.big);
      offset += 4;
      length -= 4;
    } else {
      vendor_id = 0;
    }

    if (flags.vendor) {
      vendor_id = ByteData.sublistView(data).getUint32(0, Endian.big);
    }

    return AvpHeader();
  }
}

class AvpFlags {
  bool vendor;
  bool mandatory;
  bool private;

  AvpFlags(this.vendor, this.mandatory, this.private);
}
