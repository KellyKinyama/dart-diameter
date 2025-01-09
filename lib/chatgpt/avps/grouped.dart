import 'dart:typed_data';

import 'avp.dart';

class AvpGrouped extends DiameterAVP {
  AvpGrouped({
    required int code,
    required int flags,
    required int length,
    required int vendorId,
    required List<DiameterAVP> avps,
  }) : super(
          code: code,
          flags: flags,
          length: length,
          vendorId: vendorId,
          value: _encodeAvps(avps),
        );

  // Static method to encode a list of AVPs into a grouped value
  static Uint8List _encodeAvps(List<DiameterAVP> avps) {
    final buffer = <int>[];
    final packer = Packer();

    for (var avp in avps) {
      avp.asPacked(packer); // Pack each AVP
    }

    return packer.getBuffer(); // Return the packed byte buffer
  }

  // Getter for `value` as a list of AVPs
  List<DiameterAVP> get value {
    if (!_avps.isEmpty) {
      return _avps;
    }

    final unpacker = Unpacker(this._value);
    final avps = <DiameterAVP>[];

    while (!unpacker.isDone()) {
      try {
        avps.add(DiameterAVP.decode(unpacker.next())); // Decode each AVP
      } catch (e) {
        throw AvpDecodeError(
          "Grouped AVP value is invalid: ${e.toString()}",
        );
      }
    }

    _avps = avps; // Cache the decoded AVPs
    return avps;
  }

  // Cached list of AVPs for value
  List<DiameterAVP> _avps = [];

  // Setter for `value` with a list of AVPs
  set value(List<DiameterAVP> avps) {
    _avps = avps;
    final packedAvps = _encodeAvps(avps);
    this._value = packedAvps;
    this.length = 8 + packedAvps.length;
  }

  @override
  String toString() {
    return 'AvpGrouped{code: $code, flags: $flags, length: $length, vendorId: $vendorId, value: $_avps}';
  }
}

class Unpacker {
  final List<int> _buffer;
  int _offset = 0;

  Unpacker(this._buffer);

  bool isDone() => _offset >= _buffer.length;

  List<int> next() {
    // Implement logic to extract the next AVP or data chunk from the buffer.
    // This is a dummy implementation.
    final nextAVPLength = 4; // Example length of each AVP
    final result = _buffer.sublist(_offset, _offset + nextAVPLength);
    _offset += nextAVPLength;
    return result;
  }
}

class AvpDecodeError implements Exception {
  final String message;
  AvpDecodeError(this.message);
}
