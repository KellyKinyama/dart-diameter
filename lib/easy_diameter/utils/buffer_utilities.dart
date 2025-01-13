import 'dart:typed_data';

class BufferUtilities {
  static void set3BytesToBuffer(ByteData buffer, int data) {
    buffer.setUint8(0, (data & 0xFF0000) >> 16);
    buffer.setUint8(1, (data & 0xFF00) >> 8);
    buffer.setUint8(2, data & 0xFF);
  }

  static void set4BytesToBuffer(ByteData buffer, int data) {
    buffer.setUint8(0, (data & 0xFF000000) >> 24);
    buffer.setUint8(1, (data & 0xFF0000) >> 16);
    buffer.setUint8(2, (data & 0xFF00) >> 8);
    buffer.setUint8(3, data & 0xFF);
  }

  static int get3BytesFromBuffer(ByteData buffer) {
    return ((buffer.getUint8(0) & 0xFF) << 16) |
        ((buffer.getUint8(1) & 0xFF) << 8) |
        (buffer.getUint8(2) & 0xFF);
  }

  static int get3Bytes(List<int> buffer, int index) {
    return ((buffer[index] & 0xFF) << 16) |
        ((buffer[index + 1] & 0xFF) << 8) |
        (buffer[index + 2] & 0xFF);
  }

  static int get4BytesAsUnsigned32(ByteData buffer) {
    return (((buffer.getUint8(0) & 0xFF) << 24) |
            ((buffer.getUint8(1) & 0xFF) << 16) |
            ((buffer.getUint8(2) & 0xFF) << 8) |
            (buffer.getUint8(3) & 0xFF)) &
        0xFFFFFFFF;
  }

  static int calculatePadding(int length) {
    return ((length & 3) != 0) ? (4 - (length & 3)) : 0;
  }

  static List<int> hexStringToByteArray(String s) {
    int len = s.length;
    List<int> data = List<int>.filled(len ~/ 2, 0);

    for (int i = 0; i < len; i += 2) {
      data[i ~/ 2] = (int.parse(s[i], radix: 16) << 4) + int.parse(s[i + 1], radix: 16);
    }
    return data;
  }

  static String byteToHexString(List<int> data, int start, int length) {
    const digits = '0123456789abcdef';
    StringBuffer buffer = StringBuffer();

    for (int i = start; i < start + length; i++) {
      buffer.write(digits[(0xF0 & data[i]) >> 4]);
      buffer.write(digits[0x0F & data[i]]);
    }

    return buffer.toString();
  }

  static String hexToAscii(String data) {
    int n = data.length;
    StringBuffer sb = StringBuffer();

    for (int i = 0; i < n; i += 2) {
      var a = data[i];
      var b = data[i + 1];
      sb.write(String.fromCharCode((hexToInt(a) << 4) | hexToInt(b)));
    }

    return sb.toString();
  }

  static int hexToInt(String ch) {
    if ('a'.compareTo(ch) <= 0 && 'f'.compareTo(ch) >= 0) {
      return ch.codeUnitAt(0) - 'a'.codeUnitAt(0) + 10;
    }
    if ('A'.compareTo(ch) <= 0 && 'F'.compareTo(ch) >= 0) {
      return ch.codeUnitAt(0) - 'A'.codeUnitAt(0) + 10;
    }
    if ('0'.compareTo(ch) <= 0 && '9'.compareTo(ch) >= 0) {
      return ch.codeUnitAt(0) - '0'.codeUnitAt(0);
    }
    throw ArgumentError("Invalid hex character: $ch");
  }

  static void printMessageBuffer(StringBuffer buffer, List<int> msg, int start, int length) {
    const digits = '0123456789abcdef';

    buffer.write("Message Buffer Output :");
    for (int i = start; i < start + length; i++) {
      if (i % 16 == 0) {
        buffer.write("\n");
      } else if (i % 4 == 0) {
        buffer.write(" ");
      }
      buffer.write(digits[(0xF0 & msg[i]) >> 4]);
      buffer.write(digits[0x0F & msg[i]]);
    }
  }

  static List<int> dottedIpToBytes(String ipAddress) {
    var addr = List<int>.filled(4, 0);
    var str = ipAddress.split('.');

    addr[0] = int.parse(str[0]);
    addr[1] = int.parse(str[1]);
    addr[2] = int.parse(str[2]);
    addr[3] = int.parse(str[3]);

    return addr;
  }

  static String byteToDottedIp(List<int> ipAddress) {
    String addressStr = '';
    for (var i = 0; i < 4; ++i) {
      int t = 0xFF & ipAddress[i];
      addressStr += (i == 0 ? '' : '.') + t.toString();
    }
    return addressStr;
  }
}
