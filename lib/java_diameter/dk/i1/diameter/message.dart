import 'dart:typed_data';

import 'avp.dart';
import 'message_header.dart';
import 'packunpack.dart';

/// A Diameter Message.
/// The `Message` is a container for the `MessageHeader` and the `AVP`s.
/// It supports converting to/from the on-the-wire format and manipulating the AVPs.
class Message {
  /// The message header.
  late MessageHeader hdr;

  /// List of AVPs.
  final List<AVP> avps;

  /// Default constructor. The header is initialized to default values, and the AVP list is empty.
  Message() : avps = [] {
    hdr = MessageHeader();
  }

  /// Constructor with a specific header. The AVP list will be empty.
  Message.withHeader(this.hdr) : avps = [];

  /// Copy constructor for deep copying.
  Message.copy(Message msg)
      : hdr = MessageHeader.copy(msg.hdr),
        avps = msg.avps.map((a) => AVP.copy(a)).toList();

  /// Calculate the size of the message in on-the-wire format.
  int encodeSize() {
    var size = hdr.encodeSize();
    for (var avp in avps) {
      size += avp.encodeSize();
    }
    return size;
  }

  /// Encode the message to on-the-wire format.
  Uint8List encode() {
    var size = encodeSize();
    var buffer = Uint8List(size);
    var offset = 0;
    offset += hdr.encode(buffer, offset, size);
    for (var avp in avps) {
      offset += avp.encode(buffer, offset);
    }
    return buffer;
  }

  /// Decode a message from on-the-wire format.
  DecodeStatus decode(Uint8List buffer, [int offset = 0, int bytes = 0]) {
    bytes = bytes > 0 ? bytes : buffer.length;
    if (bytes < 1) return DecodeStatus.notEnough;

    if (PackUnpack.unpack8(buffer, offset) != 1) return DecodeStatus.garbage;

    if (bytes < 4) return DecodeStatus.notEnough;

    var size = decodeSize(buffer, offset);
    if (size % 4 != 0 || size < 20 || bytes < size) return DecodeStatus.garbage;

    hdr.decode(buffer, offset);
    if (hdr.version != 1) return DecodeStatus.garbage;

    offset += 20;
    var remainingBytes = bytes - 20;
    var newAvps = <AVP>[];
    while (remainingBytes > 0) {
      if (remainingBytes < 8) return DecodeStatus.garbage;

      var avpSize = AVP.decodeSize(buffer, offset, remainingBytes);
      if (avpSize == 0 || avpSize > remainingBytes) return DecodeStatus.garbage;

      var newAvp = AVP(Uint8List(avpSize));
      if (!newAvp.decode(buffer, offset, avpSize)) return DecodeStatus.garbage;

      newAvps.add(newAvp);
      offset += avpSize;
      remainingBytes -= avpSize;
    }

    if (remainingBytes != 0) return DecodeStatus.garbage;

    avps
      ..clear()
      ..addAll(newAvps);
    return DecodeStatus.decoded;
  }

  /// Determines the size of the message from on-the-wire byte array.
  static int decodeSize(Uint8List buffer, int offset) {
    var vMl = PackUnpack.unpack32(buffer, offset);
    var v = (vMl >> 24) & 0xff;
    var ml = vMl & 0x00FFFFFF;
    if (v != 1 || ml < 20 || ml % 4 != 0) return 4; // Invalid size
    return ml;
  }

  /// Returns the number of AVPs in the message.
  int size() => avps.length;

  /// Adds an AVP at the end of the AVP list.
  void add(AVP avp) => avps.add(avp);

  /// Removes the AVP at the specified position.
  void remove(int index) => avps.removeAt(index);

  /// Finds an AVP with the specified code and vendor ID.
  AVP? find(int code, [int vendorId = 0]) {
    return avps.firstWhere(
      (avp) => avp.code == code && (vendorId == 0 || avp.vendorId == vendorId),
      orElse: () {
        throw "AVP not fount";
      },
    );
  }

  /// Returns a subset of AVPs matching the specified code and vendor ID.
  Iterable<AVP> subset(int code, [int vendorId = 0]) {
    return avps.where((avp) =>
        avp.code == code && (vendorId == 0 || avp.vendorId == vendorId));
  }

  /// Prepares a response to the supplied request.
  void prepareResponse(Message request) {
    hdr.prepareResponse(request.hdr);
  }
}

/// Decode statuses for a Diameter message.
enum DecodeStatus {
  decoded,
  notEnough,
  garbage,
}
