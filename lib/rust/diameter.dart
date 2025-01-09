import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

import 'dart:typed_data';
import 'dart:convert';
import 'package:test/test.dart';
//import 'avp/avp_value.dart';
import 'avp/identity.dart';
import 'avp/unsigned32.dart';
import 'avp/utf8_string.dart';
import 'avp/enumerated.dart';
import 'avp/integer32.dart';
//import 'package:your_project/diameter_message.dart';

const HEADER_LENGTH = 20;

class DiameterFlags {
  static const REQUEST = 0x80;
  static const PROXYABLE = 0x40;
  static const ERROR = 0x20;
  static const RETRANSMIT = 0x10;
}

class CommandCode {
  static const Error = 0;
  static const CapabilitiesExchange = 257;
  static const DeviceWatchdog = 280;
  static const DisconnectPeer = 282;
  static const ReAuth = 258;
  static const SessionTerminate = 275;
  static const AbortSession = 274;
  static const CreditControl = 272;
  static const SpendingLimit = 8388635;
  static const SpendingStatusNotification = 8388636;
  static const Accounting = 271;
  static const AA = 265;
}

class ApplicationId {
  static const Common = 0;
  static const Accounting = 3;
  static const CreditControl = 4;
  static const Gx = 16777238;
  static const Rx = 16777236;
  static const Sy = 16777302;
}

class DiameterHeader {
  final int version;
  final int length;
  final int flags;
  final int code;
  final int applicationId;
  final int hopByHopId;
  final int endToEndId;

  DiameterHeader({
    required this.version,
    required this.length,
    required this.flags,
    required this.code,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
  });

  factory DiameterHeader.decodeFrom(Uint8List data) {
    if (data.length < HEADER_LENGTH) {
      throw FormatException('Invalid diameter header, too short');
    }

    final version = data[0];
    final length = ByteData.sublistView(data).getUint32(1, Endian.big);
    final flags = data[4];
    final code = ByteData.sublistView(data).getUint32(5, Endian.big);
    final applicationId = ByteData.sublistView(data).getUint32(9, Endian.big);
    final hopByHopId = ByteData.sublistView(data).getUint32(13, Endian.big);
    final endToEndId = ByteData.sublistView(data).getUint32(17, Endian.big);

    return DiameterHeader(
      version: version,
      length: length,
      flags: flags,
      code: code,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
    );
  }

  Uint8List encodeTo() {
    final bytes = ByteData(20)
      ..setUint8(0, version)
      ..setUint32(1, length, Endian.big)
      ..setUint8(4, flags)
      ..setUint32(5, code, Endian.big)
      ..setUint32(9, applicationId, Endian.big)
      ..setUint32(13, hopByHopId, Endian.big)
      ..setUint32(17, endToEndId, Endian.big);

    return bytes.buffer.asUint8List();
  }

  String toString() {
    final requestFlag =
        (flags & DiameterFlags.REQUEST != 0) ? 'Request' : 'Answer';
    final errorFlag = (flags & DiameterFlags.ERROR != 0) ? 'Error' : '';
    final proxyableFlag =
        (flags & DiameterFlags.PROXYABLE != 0) ? 'Proxyable' : '';
    final retransmitFlag =
        (flags & DiameterFlags.RETRANSMIT != 0) ? 'Retransmit' : '';

    return '$version $code ($code) $applicationId ($applicationId) $requestFlag $errorFlag $proxyableFlag $retransmitFlag $hopByHopId $endToEndId';
  }
}

class DiameterMessage {
  DiameterHeader header;
  List<Avp> avps;
  final Dictionary dict;

  DiameterMessage({
    required this.header,
    required this.avps,
    required this.dict,
  });

  factory DiameterMessage.decodeFrom(Uint8List data, Dictionary dict) {
    final header = DiameterHeader.decodeFrom(data);
    final totalLength = header.length;
    int offset = HEADER_LENGTH;
    final avps = <Avp>[];

    while (offset < totalLength) {
      final avp = Avp.decodeFrom(data.sublist(offset), dict);
      avps.add(avp);
      offset += avp.length;
    }

    if (offset != totalLength) {
      throw FormatException('Invalid diameter message, length mismatch');
    }

    return DiameterMessage(header: header, avps: avps, dict: dict);
  }

  Uint8List encodeTo() {
    final bytes = <int>[];
    bytes.addAll(header.encodeTo());

    for (final avp in avps) {
      bytes.addAll(avp.encodeTo());
    }

    return Uint8List.fromList(bytes);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(header);
    for (final avp in avps) {
      sb.writeln(avp);
    }
    return sb.toString();
  }
}

class Avp {
  final int code;
  final int length;
  final AvpValue value;

  Avp({
    required this.code,
    required this.length,
    required this.value,
  });

  factory Avp.decodeFrom(Uint8List data, Dictionary dict) {
    final code = ByteData.sublistView(data).getUint32(0, Endian.big);
    final length = ByteData.sublistView(data).getUint32(4, Endian.big);
    final value = AvpValue.decodeFrom(data.sublist(8), dict);

    return Avp(code: code, length: length, value: value);
  }

  Uint8List encodeTo() {
    final bytes = ByteData(8 + value.length())
      ..setUint32(0, code, Endian.big)
      ..setUint32(4, length, Endian.big);

    return Uint8List.fromList(bytes.buffer.asUint8List() + value.encodeTo());
  }

  @override
  String toString() {
    return 'AVP Code: $code, Length: $length, Value: ${value.toString()}';
  }
}

class AvpValue {
  final String value;

  AvpValue(this.value);

  factory AvpValue.decodeFrom(Uint8List data, Dictionary dict) {
    return AvpValue(utf8.decode(data));
  }

  Uint8List encodeTo() {
    return utf8.encode(value);
  }

  @override
  String toString() {
    return value;
  }

  int length() {
    return value.length;
  }
}

class Dictionary {
  Dictionary();
}

void main() {
  group('DiameterMessage Tests', () {
    test('decode and encode header', () {
      final data = [
        0x01, 0x00, 0x00, 0x14, // version, length
        0x80, 0x00, 0x01, 0x10, // flags, code
        0x00, 0x00, 0x00, 0x04, // application_id
        0x00, 0x00, 0x00, 0x03, // hop_by_hop_id
        0x00, 0x00, 0x00, 0x04, // end_to_end_id
      ];

      final header = DiameterHeader.decodeFrom(Uint8List.fromList(data));
      expect(header.version, 1);
      expect(header.length, 20);
      expect(header.flags, DiameterFlags.REQUEST);
      expect(header.code, CommandCode.CreditControl);
      expect(header.applicationId, ApplicationId.CreditControl);
      expect(header.hopByHopId, 3);
      expect(header.endToEndId, 4);

      final encoded = header.encodeTo();
      expect(encoded, data);
    });

    test('decode and encode Diameter message', () {
      final dict = Dictionary();
      final data = [
        0x01, 0x00, 0x00, 0x34, // version, length
        0x80, 0x00, 0x01, 0x10, // flags, code
        0x00, 0x00, 0x00, 0x04, // application_id
        0x00, 0x00, 0x00, 0x03, // hop_by_hop_id
        0x00, 0x00, 0x00, 0x04, // end_to_end_id
        0x00, 0x00, 0x01, 0x9F, // avp code
        0x40, 0x00, 0x00, 0x0C, // flags, length
        0x00, 0x00, 0x04, 0xB0, // value
        0x00, 0x00, 0x00, 0x1E, // avp code
        0x00, 0x00, 0x00, 0x12, // flags, length
        0x66, 0x6F, 0x6F, 0x62, // value
        0x61, 0x72, 0x31, 0x32, // value
        0x33, 0x34, 0x00, 0x00,
      ];

      final message =
          DiameterMessage.decodeFrom(Uint8List.fromList(data), dict);
      final avps = message.avps;
      expect(avps.length, 2);

      final avp0 = avps[0];
      expect(avp0.getCode(), 415);
      expect(avp0.getLength(), 12);
      expect(avp0.getFlags().vendor, false);
      expect(avp0.getFlags().mandatory, true);
      expect(avp0.getFlags().private, false);
      expect(avp0.getVendorId(), null);
      expect(avp0.getValue(), isA<Unsigned32>());
      expect((avp0.getValue() as Unsigned32).value, 1200);

      final avp1 = avps[1];
      expect(avp1.getCode(), 30);
      expect(avp1.getLength(), 18);
      expect(avp1.getFlags().vendor, false);
      expect(avp1.getFlags().mandatory, false);
      expect(avp1.getFlags().private, false);
      expect(avp1.getVendorId(), null);
      expect(avp1.getValue(), isA<UTF8String>());
      expect((avp1.getValue() as UTF8String).value, 'foobar1234');

      final encoded = message.encodeTo();
      expect(encoded, data);
    });

    test('encode and decode Diameter message struct', () {
      final dict = Dictionary();
      final message = DiameterMessage.create(
        CommandCode.CreditControl,
        ApplicationId.CreditControl,
        DiameterFlags.REQUEST | DiameterFlags.PROXYABLE,
        1123158610,
        3102381851,
        dict,
      );

      message.addAvp(264, null, M, Identity('host.example.com').into());
      message.addAvp(296, null, M, Identity('realm.example.com').into());
      message.addAvp(263, null, M, UTF8String('ses;12345888').into());
      message.addAvp(268, null, M, Unsigned32(2001).into());
      message.addAvp(416, null, M, Enumerated(1).into());
      message.addAvp(415, null, M, Unsigned32(1000).into());

      final psInformation = Grouped([], dict);
      psInformation.addAvp(30, null, M, UTF8String('10999').into());
      final serviceInformation = Grouped([], dict);
      serviceInformation.addAvp(874, 10415, M, psInformation.into());

      message.addAvp(873, 10415, M, serviceInformation.into());

      final encoded = message.encodeTo();
      final decodedMessage = DiameterMessage.decodeFrom(encoded, dict);
      print('Decoded message: $decodedMessage');
    });

    test('decode CCR message', () {
      final dict = Dictionary();
      final data = [
        0x01, 0x00, 0x00, 0x54, // version, length
        0x00, 0x00, 0x01, 0x10, // flags, code
        0x00, 0x00, 0x00, 0x04, // application_id
        0x00, 0x00, 0x00, 0x00, // hop_by_hop_id
        0x00, 0x00, 0x00, 0x00, // end_to_end_id
        // Avp data...
      ];

      final message =
          DiameterMessage.decodeFrom(Uint8List.fromList(data), dict);
      print('Decoded CCR message: $message');
    });

    test('add AVP by name', () {
      final dict = Dictionary();
      final message = DiameterMessage.create(
        CommandCode.CreditControl,
        ApplicationId.CreditControl,
        DiameterFlags.REQUEST,
        1234,
        5678,
        dict,
      );

      expect(
        message.addAvpByName(
            'Origin-Host', Identity('host.example.com').into()),
        isTrue,
      );
      expect(
        message.addAvpByName(
            'Origin-Realm', Identity('realm.example.com').into()),
        isTrue,
      );
      expect(
        message.addAvpByName('Session-Id', UTF8String('ses;12345888').into()),
        isTrue,
      );
      expect(
        message.addAvpByName('Service-Context-Id', Unsigned32(2001).into()),
        isTrue,
      );
      expect(
        message.addAvpByName('Does-Not-Exist', Integer32(1234).into()),
        isFalse,
      );

      expect(message.getAvp(264) != null, isTrue);
      expect(message.getAvp(296) != null, isTrue);
      expect(message.getAvp(263) != null, isTrue);
      expect(message.getAvp(415) == null, isTrue);
    });
  });
}
