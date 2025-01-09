import 'dart:typed_data';
import 'dart:io';
import 'package:intl/intl.dart';

const int RFC868_OFFSET = 2208988800; // Diff. between 1970 and 1900 in seconds.

class Time {
  final DateTime value;

  Time(this.value);

  // Create a new Time instance
  factory Time.fromDateTime(DateTime value) {
    return Time(value);
  }

  // Get the value
  DateTime getValue() {
    return value;
  }

  // Decode a Time instance from bytes
  static Time decodeFrom(Uint8List data) {
    if (data.length < 4) {
      throw FormatException('Insufficient data for decoding');
    }

    final diameterTimestamp =
        ByteData.sublistView(data).getUint32(0, Endian.big);
    final unixTimestamp = diameterTimestamp - RFC868_OFFSET;

    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000, isUtc: true);
    return Time(timestamp);
  }

  // Encode the Time instance to bytes
  Uint8List encodeTo() {
    final unixTimestamp = value.millisecondsSinceEpoch ~/ 1000;
    final diameterTimestamp = unixTimestamp + RFC868_OFFSET;

    if (diameterTimestamp > 0xFFFFFFFF) {
      throw FormatException(
          'Time is too far in the future to fit into 32 bits');
    }

    final result = ByteData(4);
    result.setUint32(0, diameterTimestamp, Endian.big);
    return result.buffer.asUint8List();
  }

  // Return the length (4 bytes for time)
  int length() {
    return 4;
  }

  @override
  String toString() {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(value);
  }
}

void main() {
  // Test encoding and decoding
  final now = DateTime.utc(2024, 1, 10, 10, 35, 58);
  final timeInstance = Time.fromDateTime(now);

  // Encoding
  final encoded = timeInstance.encodeTo();
  print('Encoded: $encoded');

  // Decoding
  final decoded = Time.decodeFrom(Uint8List.fromList(encoded));
  print('Decoded value: ${decoded.getValue()}');
  print('Decoded string: ${decoded.toString()}');
}
