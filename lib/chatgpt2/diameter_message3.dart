// import 'dart:typed_data';

// class DiameterMessage {
//   final int version;
//   final int length;
//   final int flags;
//   final int commandCode;
//   final int applicationId;
//   final int hopByHopId;
//   final int endToEndId;
//   final List<AVP> avps;

//   DiameterMessage({
//     required this.version,
//     required this.length,
//     required this.flags,
//     required this.commandCode,
//     required this.applicationId,
//     required this.hopByHopId,
//     required this.endToEndId,
//     required this.avps,
//   });

//   static DiameterMessage decode(Uint8List data) {
//     if (data.length < 20) {
//       throw FormatException('Invalid Diameter message length');
//     }

//     final version = data[0];
//     final length =
//         ByteData.sublistView(Uint8List.fromList(data)).getInt32(2, Endian.big);
//     final flags = data[1];
//     final commandCode =
//         ByteData.sublistView(Uint8List.fromList(data)).getInt32(4, Endian.big);
//     final applicationId =
//         ByteData.sublistView(Uint8List.fromList(data)).getInt32(8, Endian.big);
//     final hopByHopId =
//         ByteData.sublistView(Uint8List.fromList(data)).getInt32(12, Endian.big);
//     final endToEndId =
//         ByteData.sublistView(Uint8List.fromList(data)).getInt32(16, Endian.big);

//     final avps = <AVP>[];
//     int offset = 20;

//     while (offset + 8 < data.length) {
//       // Ensure there is at least space for AVP header (code, length, data)
//       final avpCode = ByteData.sublistView(Uint8List.fromList(data))
//           .getInt32(offset, Endian.big);
//       final avpLength = ByteData.sublistView(Uint8List.fromList(data))
//           .getInt32(offset + 4, Endian.big);

//       // Ensure the AVP length doesn't exceed the remaining data size
//       if (offset + 8 + avpLength > data.length) {
//         throw FormatException('AVP length exceeds available data size');
//       }

//       final avpData = data.sublist(offset + 8, offset + 8 + avpLength);

//       avps.add(AVP(avpCode, avpLength, avpData));

//       offset += 8 + avpLength; // Update the offset
//     }

//     return DiameterMessage(
//       version: version,
//       length: length,
//       flags: flags,
//       commandCode: commandCode,
//       applicationId: applicationId,
//       hopByHopId: hopByHopId,
//       endToEndId: endToEndId,
//       avps: avps,
//     );
//   }
// }

// class AVP {
//   final int code;
//   final int length;
//   final List<int> data;

//   AVP(this.code, this.length, this.data);

//   @override
//   String toString() {
//     return 'AVP Code: $code, Data: $data';
//   }
// }

// void main() {
//   // Example raw data received from the client
//   final data = Uint8List.fromList([
//     // Diameter Header (version, length, flags, commandCode, applicationId, hopByHopId, endToEndId)
//     1, 0, 0, 140, 128, 0, 1, 1, 0, 0, 0, 0, 87, 166, 179, 55, 245, 178, 219,
//     227,
//     0, 0, 1, 7, 64, 0, 0, 18, 49, 51, 52, 57, 51, 52, 56, 53, 57, 57, 0, 0, 0,
//     0,
//     1, 8, 96, 0, 0, 27, 103, 120, 46, 112, 99, 101, 102, 46, 101, 120, 97, 109,
//     112, 108,
//     101, 46, 99, 111, 109, 0, 0, 0, 1, 40, 64, 0, 0, 24, 112, 99, 101, 102, 46,
//     101, 120, 97,
//     109, 112, 108, 101, 46, 99, 111, 109, 0, 0, 1, 10, 96, 0, 0, 12, 0, 0, 40,
//     175, 0, 0, 1, 22,
//     64, 0, 0, 12, 0, 3, 87, 201, 0, 0, 1, 9, 96, 0, 0, 12, 0, 0, 40, 175, 0, 0,
//     1, 2, 64, 0,
//     0, 12, 0, 0, 0, 4
//   ]);

//   try {
//     final diameterMessage = DiameterMessage.decode(data);
//     print('Diameter Message:');
//     print('Version: ${diameterMessage.version}');
//     print('Length: ${diameterMessage.length}');
//     print('Flags: ${diameterMessage.flags}');
//     print('Command Code: ${diameterMessage.commandCode}');
//     print('Application ID: ${diameterMessage.applicationId}');
//     print('Hop-by-Hop ID: ${diameterMessage.hopByHopId}');
//     print('End-to-End ID: ${diameterMessage.endToEndId}');
//     print('AVPs:');
//     for (final avp in diameterMessage.avps) {
//       print(avp);
//     }
//   } catch (e) {
//     print('Failed to decode message: $e');
//   }
// }
