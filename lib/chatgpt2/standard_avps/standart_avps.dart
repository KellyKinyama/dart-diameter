import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../diameter_message11.dart';

class OriginHostAVP extends AVP {
  OriginHostAVP(String value)
      : super(AVPCode.originHost, 0, 8 + value.length, value);

  @override
  Uint8List encode() {
    final valueBytes = utf8.encode(value);
    return Uint8List.fromList(super.encode() + valueBytes);
  }

  static OriginHostAVP decode(Uint8List data) {
    final value = utf8.decode(data);
    return OriginHostAVP(value);
  }
}

class ResultCodeAVP extends AVP {
  ResultCodeAVP(int value) : super(AVPCode.resultCode, 0, 12, value);

  @override
  Uint8List encode() {
    final buffer = ByteData(4)..setInt32(0, value, Endian.big);
    return Uint8List.fromList(super.encode() + buffer.buffer.asUint8List());
  }

  static ResultCodeAVP decode(Uint8List data) {
    final code = ByteData.sublistView(data).getInt32(0, Endian.big);
    return ResultCodeAVP(code);
  }
}
class DisconnectCauseAVP extends AVP {
  static const int REBOOTING = 0;
  static const int BUSY = 1;
  static const int DO_NOT_WANT_TO_TALK_TO_YOU = 2;

  DisconnectCauseAVP(int value)
      : super(AVPCode.disconnectCause, 0, 12, value);

  @override
  Uint8List encode() {
    final buffer = ByteData(4)..setInt32(0, value, Endian.big);
    return Uint8List.fromList(super.encode() + buffer.buffer.asUint8List());
  }

  static DisconnectCauseAVP decode(Uint8List data) {
    final cause = ByteData.sublistView(data).getInt32(0, Endian.big);
    return DisconnectCauseAVP(cause);
  }
}

class DisconnectPeerAnswer extends DiameterMessage {
  DisconnectPeerAnswer({
    required String originHost,
    required String originRealm,
    required int resultCode,
  }) : super(
          version: 1,
          length: 0, // Placeholder
          flags: 0x00, // Answer flag
          commandCode: 282, // DPA command code
          applicationId: 0,
          hopByHopId: _generateHopByHopId(),
          endToEndId: _generateEndToEndId(),
          avps: [
            OriginHostAVP(originHost),
            OriginRealmAVP(originRealm),
            ResultCodeAVP(resultCode),
          ],
        );

  static int _generateHopByHopId() => Random().nextInt(0xFFFFFFFF);
  static int _generateEndToEndId() => Random().nextInt(0xFFFFFFFF);
}
