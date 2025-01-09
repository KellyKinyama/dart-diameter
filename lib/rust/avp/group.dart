import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

// Dummy Dictionary class for illustration
class Dictionary {
  final List<String> dict;

  Dictionary(this.dict);

  // Dummy method to simulate the actual dictionary lookup in Rust.
  String lookup(int code) => 'Dictionary lookup for $code';
}

class AvpValue {
  final dynamic value;

  AvpValue(this.value);

  static AvpValue Enumerated(int value) => AvpValue(value);

  static AvpValue Unsigned32(int value) => AvpValue(value);
}

class Avp {
  final int code;
  final int? vendorId;
  final int flags;
  final AvpValue value;
  final Dictionary dict;

  Avp(this.code, this.vendorId, this.flags, this.value, this.dict);

  // Decode an Avp from a byte list (stubbed for now)
  static Avp decodeFrom(List<int> data, Dictionary dict) {
    // Simulated decoding
    final code = data[0]; // Just as an example
    final value = AvpValue.Unsigned32(100); // Placeholder value
    return Avp(code, null, 0, value, dict);
  }

  void encodeTo(List<int> writer) {
    writer.add(code); // Add code to writer
    // Here we would encode more attributes
  }

  int getLength() {
    return 4; // Placeholder for length calculation
  }

  int getPadding() {
    return 0; // Placeholder for padding
  }

  int getCode() {
    return code;
  }

  AvpValue getValue() {
    return value;
  }

  // Placeholder for Avp formatting
  void fmt(StringBuffer sb, int depth) {
    sb.write('Avp Code: $code');
  }
}

class Grouped {
  final List<Avp> avps;
  final Dictionary dict;

  Grouped(this.avps, this.dict);

  // Add an AVP to the group
  void add(Avp avp) {
    avps.add(avp);
  }

  // Add an AVP with specific parameters
  void addAvp(int code, int? vendorId, int flags, AvpValue value) {
    final avp = Avp(code, vendorId, flags, value, dict);
    add(avp);
  }

  // Decode a Grouped AVP from a byte list
  static Grouped decodeFrom(List<int> data, int length, Dictionary dict) {
    final avps = <Avp>[];
    int offset = 0;

    while (offset < length) {
      final avp = Avp.decodeFrom(data.sublist(offset), dict);
      avps.add(avp);
      offset += avp.getLength();
    }

    return Grouped(avps, dict);
  }

  // Encode the Grouped AVP to a byte list
  void encodeTo(List<int> writer) {
    for (final avp in avps) {
      avp.encodeTo(writer);
    }
  }

  // Get the total length of the Grouped AVP
  int length() {
    return avps.fold(0, (sum, avp) => sum + avp.getLength() + avp.getPadding());
  }

  // Format the Grouped AVP for printing
  String fmt(int depth) {
    final sb = StringBuffer();
    for (final avp in avps) {
      sb.writeln(' ' * depth + 'AVP:');
      avp.fmt(sb, depth + 1);
    }
    return sb.toString();
  }

  @override
  String toString() {
    return fmt(0);
  }
}

void main() {
  final dict = Dictionary(['default_dict']); // Simulated dictionary for testing
  final groupedAvp = Grouped([], dict);

  groupedAvp.addAvp(416, null, 0, AvpValue.Enumerated(1));
  groupedAvp.addAvp(415, null, 0, AvpValue.Unsigned32(1000));

  // Print grouped AVP
  print(groupedAvp);

  // Encode Grouped AVP
  final encoded = <int>[];
  groupedAvp.encodeTo(encoded);
  print('Encoded: $encoded');

  // Decode back
  final decodedGroupedAvp = Grouped.decodeFrom(encoded, encoded.length, dict);
  print('Decoded: $decodedGroupedAvp');
}
