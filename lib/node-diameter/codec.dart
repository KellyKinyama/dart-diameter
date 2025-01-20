import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

class DiameterMessage {
  static const DIAMETER_MESSAGE_HEADER_LENGTH_IN_BYTES = 20;
  static const DIAMETER_MESSAGE_AVP_HEADER_LENGTH_IN_BYTES = 8;
  static const DIAMETER_MESSAGE_VENDOR_ID_LENGTH_IN_BYTES = 4;

  // Byte positions for header fields
  static const DIAMETER_MESSAGE_HEADER_VERSION = 0;
  static const DIAMETER_MESSAGE_HEADER_LENGTH = 1;
  static const DIAMETER_MESSAGE_HEADER_COMMAND_CODE = 5;
  static const DIAMETER_MESSAGE_HEADER_FLAGS = 4;
  static const DIAMETER_MESSAGE_HEADER_FLAG_REQUEST = 0;
  static const DIAMETER_MESSAGE_HEADER_FLAG_PROXIABLE = 1;
  static const DIAMETER_MESSAGE_HEADER_FLAG_ERROR = 2;
  static const DIAMETER_MESSAGE_HEADER_FLAG_POTENTIALLY_RETRANSMITTED = 3;
  static const DIAMETER_MESSAGE_HEADER_APPLICATION_ID = 8;
  static const DIAMETER_MESSAGE_HEADER_HOP_BY_HOP_ID = 12;
  static const DIAMETER_MESSAGE_HEADER_END_TO_END_ID = 16;

  // Byte positions for AVP fields
  static const DIAMETER_MESSAGE_AVP_CODE = 0;
  static const DIAMETER_MESSAGE_AVP_FLAGS = 4;
  static const DIAMETER_MESSAGE_AVP_FLAG_VENDOR = 0;
  static const DIAMETER_MESSAGE_AVP_FLAG_MANDATORY = 1;
  static const DIAMETER_MESSAGE_AVP_LENGTH = 5;
  static const DIAMETER_MESSAGE_AVP_VENDOR_ID = 8;
  static const DIAMETER_MESSAGE_AVP_VENDOR_ID_DATA = 12;
  static const DIAMETER_MESSAGE_AVP_NO_VENDOR_ID_DATA = 8;

  static int readUInt24BE(Uint8List buffer, int offset) {
    return (buffer[offset] << 16) + (buffer[offset + 1] << 8) + buffer[offset + 2];
  }

  static void writeUInt24BE(Uint8List buffer, int offset, int value) {
    buffer[offset] = (value >> 16) & 0xFF;
    buffer[offset + 1] = (value >> 8) & 0xFF;
    buffer[offset + 2] = value & 0xFF;
  }

  static bool getBit(int num, int bit) {
    return ((num >> (7 - bit)) & 1) != 0;
  }

  static int getIntFromBits(List<bool> array) {
    String s = array.map((bit) => bit ? '1' : '0').join();
    return int.parse(s, radix: 2);
  }

  static DiameterMessageHeader decodeMessageHeader(Uint8List buffer) {
    var messageHeader = DiameterMessageHeader();
    messageHeader.version = buffer[DIAMETER_MESSAGE_HEADER_VERSION];
    messageHeader.length = readUInt24BE(buffer, DIAMETER_MESSAGE_HEADER_LENGTH);
    messageHeader.commandCode = readUInt24BE(buffer, DIAMETER_MESSAGE_HEADER_COMMAND_CODE);

    int flags = buffer[DIAMETER_MESSAGE_HEADER_FLAGS];
    messageHeader.flags = DiameterMessageFlags(
      request: getBit(flags, DIAMETER_MESSAGE_HEADER_FLAG_REQUEST),
      proxiable: getBit(flags, DIAMETER_MESSAGE_HEADER_FLAG_PROXIABLE),
      error: getBit(flags, DIAMETER_MESSAGE_HEADER_FLAG_ERROR),
      potentiallyRetransmitted: getBit(flags, DIAMETER_MESSAGE_HEADER_FLAG_POTENTIALLY_RETRANSMITTED),
    );

    messageHeader.applicationId = ByteData.sublistView(buffer).getInt32(DIAMETER_MESSAGE_HEADER_APPLICATION_ID, Endian.big);
    messageHeader.hopByHopId = ByteData.sublistView(buffer).getInt32(DIAMETER_MESSAGE_HEADER_HOP_BY_HOP_ID, Endian.big);
    messageHeader.endToEndId = ByteData.sublistView(buffer).getInt32(DIAMETER_MESSAGE_HEADER_END_TO_END_ID, Endian.big);

    return messageHeader;
  }

  static void inflateMessageHeader(DiameterMessageHeader header, Dictionary dictionary) {
    var command = dictionary.getCommandByCode(header.commandCode);
    if (command == null) {
      throw Exception('Can\'t find command with code ${header.commandCode}');
    }
    header.command = command.name;
    var application = dictionary.getApplicationById(header.applicationId);
    if (application == null) {
      throw Exception('Can\'t find application with ID ${header.applicationId}');
    }
    header.application = application.name;
  }

  // static DiameterRequest constructRequest(String applicationName, String commandName, String sessionId, Dictionary dictionary) {
  //   var application = findApplication(applicationName, dictionary);
  //   if (application == null) {
  //     throw Exception('Application $applicationName not found in dictionary.');
  //   }
  //   var command = findCommand(commandName, dictionary);
  //   if (command == null) {
  //     throw Exception('Command $commandName not found in dictionary.');
  //   }

  //   return DiameterRequest(
  //     header: DiameterMessageHeader(
  //       version: 1,
  //       commandCode: int.parse(command.code),
  //       flags: DiameterMessageFlags(request: true),
  //       applicationId: int.parse(application.code),
  //       application: application.name,
  //       hopByHopId: -1,
  //       endToEndId: random32BitNumber(),
  //     ),
  //     body: [['Session-Id', sessionId]],
  //     command: command.name,
  //   );
  // }

  // static DiameterResponse constructResponse(DiameterMessageHeader message) {
  //   return DiameterResponse(
  //     header: DiameterMessageHeader(
  //       version: message.version,
  //       commandCode: message.commandCode,
  //       flags: DiameterMessageFlags(
  //         request: false,
  //         proxiable: message.flags.proxiable,
  //         error: false,
  //         potentiallyRetransmitted: message.flags.potentiallyRetransmitted,
  //       ),
  //       applicationId: message.applicationId,
  //       application: message.application,
  //       hopByHopId: message.hopByHopId,
  //       endToEndId: message.endToEndId,
  //     ),
  //     body: message.body,
  //     command: message.command,
  //   );
  // }

  static List<AVP> decodeAvps(Uint8List buffer, int start, int end, int appId, Dictionary dictionary) {
    var avps = <AVP>[];
    int cursor = start;
    while (cursor < end) {
      var avp = decodeAvp(buffer, cursor, appId, dictionary);
      avps.add(avp);
      cursor += avp.length;
      if (cursor % 4 != 0) {
        cursor += 4 - cursor % 4;
      }
    }
    return avps;
  }

  static AVP decodeAvp(Uint8List buffer, int start, int appId, Dictionary dictionary) {
    var avp = decodeAvpHeader(buffer, start);

    var hasVendorId = avp.flags.vendor;
    if (hasVendorId) {
      avp.vendorId = ByteData.sublistView(buffer).getInt32(start + DIAMETER_MESSAGE_AVP_VENDOR_ID, Endian.big);
    } else {
      avp.vendorId = 0;
    }

    try {
      var avpTag = dictionary.getAvpByCodeAndVendorId(avp.codeInt, avp.vendorId);
      if (avpTag == null) {
        throw Exception('Unable to find AVP for code ${avp.codeInt} and vendor id ${avp.vendorId}, for app $appId');
      }
      avp.code = avpTag.name;

      int dataPosition = hasVendorId ? DIAMETER_MESSAGE_AVP_VENDOR_ID_DATA : DIAMETER_MESSAGE_AVP_NO_VENDOR_ID_DATA;
      avp.dataRaw = buffer.sublist(start + dataPosition, start + avp.length);
      if (avpTag.type == 'Grouped') {
        avp.avps = decodeAvps(avp.dataRaw, 0, avp.dataRaw.length, appId, dictionary);
      } else {
        avp.data = diameterTypes.decode(avpTag.type, avp.dataRaw);
        if (avpTag.type == 'AppId') {
          var application = dictionary.getApplicationById(avp.data);
          if (application == null) {
            throw Exception('Can\'t find application with ID ${avp.data}');
          }
          avp.data = application.name;
        } else if (avpTag.enums != null) {
          var enumValue = avpTag.enums!.firstWhere(
              (e) => e.code == avp.data,
              orElse: () => throw Exception('No enum value found for ${avp.code} code ${avp.data}'));
          avp.data = enumValue.name;
        }
      }
    } catch (e) {
      if (avp.flags.mandatory) {
        rethrow;
      }
    }

    return avp;
  }

  static DiameterMessage decodeMessage(Uint8List buffer, Dictionary dictionary) {
    var messageHeader = decodeMessageHeader(buffer);
    var avps = decodeAvps(buffer, DIAMETER_MESSAGE_HEADER_LENGTH_IN_BYTES, messageHeader.length, messageHeader.applicationId, dictionary);
    inflateMessageHeader(messageHeader, dictionary);
    messageHeader.body = avpsToArrayForm(avps);
    messageHeader._timeProcessed = DateTime.now().millisecondsSinceEpoch;
    return DiameterMessage(messageHeader);
  }

  static List<List<dynamic>> avpsToArrayForm(List<AVP> avps) {
    return avps.map((avp) {
      if (avp.avps != null) {
        return [avp.code, avpsToArrayForm(avp.avps!)];
      }
      return [avp.code, avp.data];
    }).toList();
  }

  static int random32BitNumber() {
    var random = Random();
    return random.nextInt(0xFFFFFFFF);
  }
}

class DiameterMessageHeader {
  int version = 0;
  int length = 0;
  int commandCode = 0;
  DiameterMessageFlags flags = DiameterMessageFlags();
  int applicationId = 0;
  int hopByHopId = 0;
  int endToEndId = 0;
  String command = '';
  String application = '';
  List body = [];
  int _timeProcessed = 0;
}

class DiameterMessageFlags {
  bool request = false;
  bool proxiable = false;
  bool error = false;
  bool potentiallyRetransmitted = false;

  DiameterMessageFlags({this.request = false, this.proxiable = false, this.error = false, this.potentiallyRetransmitted = false});
}

class DiameterRequest {
  DiameterMessageHeader header;
  List<List<String>> body;
  String command;

  DiameterRequest({required this.header, required this.body, required this.command});
}

class DiameterResponse {
  DiameterMessageHeader header;
  List<List<String>> body;
  String command;

  DiameterResponse({required this.header, required this.body, required this.command});
}

class AVP {
  String code = '';
  dynamic data;
  List<AVP>? avps;
  int length = 0;
  int vendorId = 0;
  AVPFlags flags = AVPFlags();
  Uint8List dataRaw = Uint8List(0);
}

class AVPFlags {
  bool vendor = false;
  bool mandatory = false;

  AVPFlags({this.vendor = false, this.mandatory = false});
}

class Dictionary {
  // Placeholder methods for the dictionary lookups
  dynamic getCommandByCode(int code) {
    return null;
  }

  dynamic getApplicationById(int id) {
    return null;
  }

  dynamic getAvpByCodeAndVendorId(int code, int vendorId) {
    return null;
  }

  dynamic getAvpByName(String name) {
    return null;
  }

  dynamic getAvpByCode(int code) {
    return null;
  }
}

class diameterTypes {
  static dynamic decode(String type, Uint8List data) {
    return null;
  }

  static Uint8List encode(String type, dynamic value) {
    return Uint8List(0);
  }
}
