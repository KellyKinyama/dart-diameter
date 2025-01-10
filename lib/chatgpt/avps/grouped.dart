import 'dart:typed_data';
import 'dart:convert';

// Define the base AVP class
abstract class AVP {
  Uint8List get value; // Getter should return Uint8List for all derived classes
}


class GroupedAVP extends AVP {
  final List<AVP> avps;

  GroupedAVP(this.avps);

  // Decode a GroupedAVP from a list of bytes
  static GroupedAVP decode(Uint8List bytes) {
    final avps = <AVP>[];
    int offset = 0;

    while (offset < bytes.length) {
      // Assuming each AVP has a fixed length for simplicity
      // You may need to adjust this based on your actual AVP structure
      final length = 4; // Example fixed length, replace with actual logic
      final avpBytes = bytes.sublist(offset, offset + length);
      final avp = Enumerated.decode(avpBytes); // Replace with actual decoding logic
      avps.add(avp);
      offset += length;
    }

    return GroupedAVP(avps);
  }

  // Encode the GroupedAVP to a list of bytes
  Uint8List encodeTo() {
    final bytes = <int>[];
    for (final avp in avps) {
      bytes.addAll(avp.value);
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Uint8List get value => encodeTo();

  @override
  String toString() {
    return avps.toString();
  }
}

void main() {
  // Example usage for encoding and decoding GroupedAVP

  final avp1 = Enumerated.fromInt(1);
  final avp2 = Enumerated.fromInt(2);
  final groupedAVP = GroupedAVP([avp1, avp2]);

  // Encode to byte array
  final encoded = groupedAVP.encodeTo();
  print('Encoded GroupedAVP: $encoded');

  // Decode from byte array
  final decoded = GroupedAVP.decode(Uint8List.fromList(encoded));
  print('Decoded GroupedAVP: ${decoded.toString()}');
}