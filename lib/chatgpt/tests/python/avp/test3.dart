import 'dart:typed_data';
import 'dart:convert';

class AvpAddress {
  final int code;
  int family = 0;
  String _address = '';

  AvpAddress(this.code);

  // Setter for the value
  set value(String address) {
    if (RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(address)) {
      // IPv4
      family = 1;
    } else if (RegExp(r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$')
        .hasMatch(address)) {
      // IPv6
      family = 2;
    } else {
      // Assume E.164
      family = 8;
    }
    _address = address;
  }

  // Getter for the value
  String get value => _address;

  // Retrieve the family type
  int get addressFamily => family;

  // Compute payload
  Uint8List get payload {
    final buffer = BytesBuilder();
    buffer.addByte(0); // Reserved byte
    buffer.addByte(family);

    if (family == 1) {
      // IPv4: Add address bytes
      final octets = _address.split('.').map(int.parse).toList();
      buffer.add(octets);
    } else if (family == 2) {
      // IPv6: Convert address to bytes
      final segments = _address
          .split(':')
          .map((seg) {
            final padded = seg.padLeft(4, '0');
            return Uint8List.fromList([
              int.parse(padded.substring(0, 2), radix: 16),
              int.parse(padded.substring(2, 4), radix: 16),
            ]);
          })
          .expand((x) => x)
          .toList();
      buffer.add(segments);
    } else if (family == 8) {
      // E.164: Encode as ASCII bytes
      buffer.add(utf8.encode(_address));
    }

    return buffer.toBytes();
  }
}

void testCreateAddressType() {
  // Test IPv4
  final a1 = AvpAddress(1); // Code for 3GPP SGSN Address
  a1.value = "193.16.219.96";
  assert(a1.value == "193.16.219.96");
  assert(a1.addressFamily == 1);
  assert(a1.payload.toList().toString() ==
      [0x00, 0x01, 0xc1, 0x10, 0xdb, 0x60].toString());

  // Test IPv6
  final a2 = AvpAddress(2); // Code for 3GPP PDP Address
  a2.value = "8b71:8c8a:1e29:716a:6184:7966:fd43:4200";
  assert(a2.value == "8b71:8c8a:1e29:716a:6184:7966:fd43:4200");
  assert(a2.addressFamily == 2);
  assert(a2.payload.toList().toString() ==
      [
        0x00,
        0x02,
        0x8b,
        0x71,
        0x8c,
        0x8a,
        0x1e,
        0x29,
        0x71,
        0x6a,
        0x61,
        0x84,
        0x79,
        0x66,
        0xfd,
        0x43,
        0x42,
        0x00
      ].toString());

  // Test E.164
  final a3 = AvpAddress(3); // Code for 3GPP SMSC Address
  a3.value = "48507909008";
  assert(a3.value == "48507909008");
  assert(a3.addressFamily == 8);
  assert(a3.payload.toList().toString() ==
      [
        0x00,
        0x08,
        0x34,
        0x38,
        0x35,
        0x30,
        0x37,
        0x39,
        0x30,
        0x39,
        0x30,
        0x30,
        0x38
      ].toString());

  print('All tests passed!');
}

void main() {
  testCreateAddressType();
}
