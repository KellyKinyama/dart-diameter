import 'dart:typed_data';

import '../utils/buffer_utilities.dart';
import '../utils/protocol_defintions.dart';
import '../utils/protocol_utilities.dart';
// import 'package:your_project/protocol_definitions.dart';
// import 'package:your_project/protocol_utilities.dart';
// import 'package:your_project/buffer_utilities.dart';

class DiameterHeader {
  late int version;
  late int messageLength;
  late int commandFlags;
  late int commandCode;
  late int applicationId;
  late int hopByHopId;
  late int endToEndId;

  DiameterHeader(this.version, this.commandFlags, this.commandCode,
      this.applicationId, this.hopByHopId, this.endToEndId) {
    messageLength = ProtocolDefinitions.DIAMETER_MSG_HDR_LEN;
  }

  DiameterHeader.withDefaults(
      int version, int commandFlags, int commandCode, int applicationId) {
    messageLength = ProtocolDefinitions.DIAMETER_MSG_HDR_LEN;
    this.version = version;
    this.commandFlags = commandFlags;
    this.commandCode = commandCode;
    this.applicationId = applicationId;
    hopByHopId = ProtocolUtilities.createHopByHopId();
    endToEndId = ProtocolUtilities.createEndToEndId();
  }

  DiameterHeader.withCommandCodeAndAppId(
      int commandCode, int commandFlags, int applicationId) {
    this.version = ProtocolDefinitions.DIAMETER_VERSION;
    this.messageLength = ProtocolDefinitions.DIAMETER_MSG_HDR_LEN;
    this.commandCode = commandCode;
    this.commandFlags = commandFlags;
    this.applicationId = applicationId;
    hopByHopId = ProtocolUtilities.createHopByHopId();
    endToEndId = ProtocolUtilities.createEndToEndId();
  }

  DiameterHeader.empty() {
    // Default constructor can be left empty
  }

  void encode(ByteData buffer) {
    buffer.buffer.asByteData().setInt8(0, version);
    BufferUtilities.set3BytesToBuffer(buffer, messageLength);
    buffer.buffer.asByteData().setInt8(1, commandFlags);
    BufferUtilities.set3BytesToBuffer(buffer, commandCode);
    BufferUtilities.set4BytesToBuffer(buffer, applicationId);
    BufferUtilities.set4BytesToBuffer(buffer, hopByHopId);
    BufferUtilities.set4BytesToBuffer(buffer, endToEndId);
  }

  bool isRequest() =>
      (commandFlags & ProtocolDefinitions.HEADER_MASK_BIT_R) != 0;

  bool isProxiable() =>
      (commandFlags & ProtocolDefinitions.HEADER_MASK_BIT_P) != 0;

  bool isError() => (commandFlags & ProtocolDefinitions.HEADER_MASK_BIT_E) != 0;

  bool isRetransmit() =>
      (commandFlags & ProtocolDefinitions.HEADER_MASK_BIT_T) != 0;

  DiameterHeader setRequest(bool isRequest) {
    if (isRequest) {
      commandFlags |= ProtocolDefinitions.HEADER_MASK_BIT_R;
    } else {
      commandFlags &= ~ProtocolDefinitions.HEADER_MASK_BIT_R;
    }
    return this;
  }

  DiameterHeader setProxiable(bool isProxiable) {
    if (isProxiable) {
      commandFlags |= ProtocolDefinitions.HEADER_MASK_BIT_P;
    } else {
      commandFlags &= ~ProtocolDefinitions.HEADER_MASK_BIT_P;
    }
    return this;
  }

  DiameterHeader setError(bool isError) {
    if (isError) {
      commandFlags |= ProtocolDefinitions.HEADER_MASK_BIT_E;
    } else {
      commandFlags &= ~ProtocolDefinitions.HEADER_MASK_BIT_E;
    }
    return this;
  }

  DiameterHeader setRetransmit(bool isRetransmit) {
    if (isRetransmit) {
      commandFlags |= ProtocolDefinitions.HEADER_MASK_BIT_T;
    } else {
      commandFlags &= ~ProtocolDefinitions.HEADER_MASK_BIT_T;
    }
    return this;
  }

  int getVersion() {
    return version;
  }

  void setVersion(int version) {
    this.version = version;
  }

  int getCommandCode() {
    return commandCode;
  }

  void setCommandCode(int commandCode) {
    this.commandCode = commandCode;
  }

  int getApplicationId() {
    return applicationId;
  }

  void setApplicationId(int applicationId) {
    this.applicationId = applicationId;
  }

  int getMessageLength() {
    return messageLength;
  }

  void setMessageLength(int messageLength) {
    this.messageLength = messageLength;
  }

  int getCommandFlags() {
    return commandFlags;
  }

  void setCommandFlags(int commandFlags) {
    this.commandFlags = commandFlags;
  }

  int getHopByHopId() {
    return hopByHopId;
  }

  void setHopByHopId(int hopByHopId) {
    this.hopByHopId = hopByHopId;
  }

  int getEndToEndId() {
    return endToEndId;
  }

  void setEndToEndId(int endToEndId) {
    this.endToEndId = endToEndId;
  }

  void addLengthToMessage(int length) {
    messageLength += length;
  }
}
