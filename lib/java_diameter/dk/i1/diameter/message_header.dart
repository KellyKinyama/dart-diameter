import 'dart:typed_data';

import 'packunpack.dart';

/// A Diameter message header.
/// See RFC3588 section 3. 
///
/// The only fields and methods you will normally use are:
/// - `commandCode`
/// - `applicationId`
/// - `setProxiable`
/// - `setRequest`
///
/// Note: The default command flags do not include the proxiable bit, meaning
/// that request messages by default cannot be proxied by Diameter proxies and
/// other gateways. You should always call `setProxiable` explicitly to ensure it
/// has the expected value.
class MessageHeader {
  int version = 1;
  int commandCode = 0;
  int applicationId = 0;
  int hopByHopIdentifier = 0;
  int endToEndIdentifier = 0;

  int _commandFlags = 0;

  static const int commandFlagRequestBit = 0x80;
  static const int commandFlagProxiableBit = 0x40;
  static const int commandFlagErrorBit = 0x20;
  static const int commandFlagRetransmitBit = 0x10;

  /// Default constructor.
  /// Initializes the command flags to 0 (answer + not-proxiable + not-error + not-retransmit).
  MessageHeader();

  /// Copy constructor.
  /// Implements a deep copy.
  MessageHeader.copy(MessageHeader mh)
      : version = mh.version,
        _commandFlags = mh._commandFlags,
        commandCode = mh.commandCode,
        applicationId = mh.applicationId,
        hopByHopIdentifier = mh.hopByHopIdentifier,
        endToEndIdentifier = mh.endToEndIdentifier;

  /// Checks if the request bit is set.
  bool isRequest() => (_commandFlags & commandFlagRequestBit) != 0;

  /// Checks if the proxiable bit is set.
  bool isProxiable() => (_commandFlags & commandFlagProxiableBit) != 0;

  /// Checks if the error bit is set.
  bool isError() => (_commandFlags & commandFlagErrorBit) != 0;

  /// Checks if the retransmit bit is set.
  bool isRetransmit() => (_commandFlags & commandFlagRetransmitBit) != 0;

  /// Sets or clears the request bit.
  void setRequest(bool value) {
    if (value) {
      _commandFlags |= commandFlagRequestBit;
    } else {
      _commandFlags &= ~commandFlagRequestBit;
    }
  }

  /// Sets or clears the proxiable bit.
  void setProxiable(bool value) {
    if (value) {
      _commandFlags |= commandFlagProxiableBit;
    } else {
      _commandFlags &= ~commandFlagProxiableBit;
    }
  }

  /// Sets or clears the error bit.
  void setError(bool value) {
    if (value) {
      _commandFlags |= commandFlagErrorBit;
    } else {
      _commandFlags &= ~commandFlagErrorBit;
    }
  }

  /// Sets or clears the retransmit bit.
  void setRetransmit(bool value) {
    if (value) {
      _commandFlags |= commandFlagRetransmitBit;
    } else {
      _commandFlags &= ~commandFlagRetransmitBit;
    }
  }

  /// Calculates the size of the encoded message header.
  int encodeSize() => 5 * 4;

  /// Encodes the message header into the provided byte buffer.
  int encode(Uint8List buffer, int offset, int messageLength) {
    PackUnpack.pack32(buffer, offset, messageLength);
    PackUnpack.pack8(buffer, offset, version);
    PackUnpack.pack32(buffer, offset + 4, commandCode);
    PackUnpack.pack8(buffer, offset + 4, _commandFlags);
    PackUnpack.pack32(buffer, offset + 8, applicationId);
    PackUnpack.pack32(buffer, offset + 12, hopByHopIdentifier);
    PackUnpack.pack32(buffer, offset + 16, endToEndIdentifier);
    return 5 * 4;
  }

  /// Decodes the message header from the provided byte buffer.
  void decode(Uint8List buffer, int offset) {
    version = PackUnpack.unpack8(buffer, offset);
    _commandFlags = PackUnpack.unpack8(buffer, offset + 4);
    commandCode = PackUnpack.unpack32(buffer, offset + 4) & 0x00FFFFFF;
    applicationId = PackUnpack.unpack32(buffer, offset + 8);
    hopByHopIdentifier = PackUnpack.unpack32(buffer, offset + 12);
    endToEndIdentifier = PackUnpack.unpack32(buffer, offset + 16);
  }

  /// Prepares a response from the specified request header.
  /// Copies the proxiable flag and clears other flags.
  /// Copies `commandCode`, `applicationId`, `hopByHopIdentifier`,
  /// `endToEndIdentifier`, and the proxiable command flag.
  void prepareResponse(MessageHeader request) {
    _commandFlags = request._commandFlags & commandFlagProxiableBit;
    commandCode = request.commandCode;
    applicationId = request.applicationId;
    hopByHopIdentifier = request.hopByHopIdentifier;
    endToEndIdentifier = request.endToEndIdentifier;
  }

  /// Prepares an answer from the specified request header.
  /// Identical to `prepareResponse()`.
  void prepareAnswer(MessageHeader request) => prepareResponse(request);
}


