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

//   // Decode Diameter message from raw data
//   factory DiameterMessage.decode(Uint8List data) {
//     if (data.length < 20) {
//       throw FormatException("Invalid Diameter message length");
//     }

//     final version = data[0];
//     final length = (data[1] << 16) | (data[2] << 8) | data[3];
//     final flags = data[4];
//     final commandCode = (data[5] << 16) | (data[6] << 8) | data[7];
//     final applicationId =
//         (data[8] << 24) | (data[9] << 16) | (data[10] << 8) | data[11];
//     final hopByHopId =
//         (data[12] << 24) | (data[13] << 16) | (data[14] << 8) | data[15];
//     final endToEndId =
//         (data[16] << 24) | (data[17] << 16) | (data[18] << 8) | data[19];

//     List<AVP> avps = [];
//     int offset = 20; // Start after header

//     // Decode AVPs
//     while (offset + 8 <= data.length) {
//       final avpCode = (data[offset] << 24) |
//           (data[offset + 1] << 16) |
//           (data[offset + 2] << 8) |
//           data[offset + 3];
//       final avpFlags = data[offset + 4];
//       final avpLength =
//           (data[offset + 5] << 16) | (data[offset + 6] << 8) | data[offset + 7];

//       // Debugging: Print AVP code and length
//       print('AVP Code: $avpCode, AVP Length: $avpLength, Offset: $offset');

//       // Validate AVP length and ensure it does not exceed the remaining data
//       if (offset + avpLength > data.length) {
//         print('Warning: AVP length exceeds available data size. Skipping AVP.');
//         break; // Skip this AVP if the length is invalid
//       }

//       final avpData = data.sublist(offset + 8, offset + avpLength);
//       avps.add(AVP(avpCode, avpFlags, avpLength, avpData));

//       offset += avpLength;
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
//   final int avpCode;
//   final int flags;
//   final int length;
//   final List<int> data;

//   AVP(this.avpCode, this.flags, this.length, this.data);

//   // Decode AVP based on its code
//   dynamic decode() {
//     switch (avpCode) {
//       case 417:
//         return 'CC-Request-Type: ${data[0]}'; // AVP 417 corresponds to CC-Request-Type
//       case 418:
//         return 'CC-Request-Number: ${ByteData.sublistView(Uint8List.fromList(data)).getInt32(0, Endian.big)}'; // AVP 418 corresponds to CC-Request-Number
//       case 437:
//         return 'Requested-Service-Unit: ${data}'; // Requested-Service-Unit (custom logic to decode)
//       case 451:
//         return 'Service-Context-ID: ${String.fromCharCodes(data)}'; // AVP 451 corresponds to Service-Context-ID
//       case 443:
//         return 'Subscription-Id: ${ByteData.sublistView(Uint8List.fromList(data)).getInt32(0, Endian.big)}'; // AVP 443 corresponds to Subscription-Id
//       default:
//         return 'AVP Code: $avpCode, Data: ${data}';
//     }
//   }

//   @override
//   String toString() {
//     return decode().toString();
//   }
// }

// void main() {
//   // Your Diameter Credit-Control Request message data (replace with your actual data)
//   final data = Uint8List.fromList([
//     1,
//     0,
//     0,
//     140,
//     128,
//     0,
//     1,
//     1,
//     0,
//     0,
//     0,
//     0,
//     87,
//     166,
//     179,
//     55,
//     245,
//     178,
//     219,
//     227,
//     0,
//     0,
//     1,
//     7,
//     64,
//     0,
//     0,
//     18,
//     49,
//     51,
//     52,
//     57,
//     51,
//     52,
//     56,
//     53,
//     57,
//     57,
//     0,
//     0,
//     0,
//     0,
//     1,
//     8,
//     96,
//     0,
//     0,
//     27,
//     103,
//     120,
//     46,
//     112,
//     99,
//     101,
//     102,
//     46,
//     101,
//     120,
//     97,
//     109,
//     112,
//     108,
//     101,
//     46,
//     99,
//     111,
//     109,
//     0,
//     0,
//     0,
//     1,
//     40,
//     64,
//     0,
//     0,
//     24,
//     112,
//     99,
//     101,
//     102,
//     46,
//     101,
//     120,
//     97,
//     109,
//     112,
//     108,
//     101,
//     46,
//     99,
//     111,
//     109,
//     0,
//     0,
//     1,
//     10,
//     96,
//     0,
//     0,
//     12,
//     0,
//     0,
//     40,
//     175,
//     0,
//     0,
//     1,
//     22,
//     64,
//     0,
//     0,
//     12,
//     0,
//     3,
//     87,
//     201,
//     0,
//     0,
//     1,
//     9,
//     96,
//     0,
//     0,
//     12,
//     0,
//     0,
//     40,
//     175,
//     0,
//     0,
//     1,
//     2,
//     64,
//     0,
//     0,
//     12,
//     0,
//     0,
//     0,
//     4
//   ]);

//   try {
//     // Decode the Diameter message
//     final message = DiameterMessage.decode(data);

//     // Output the decoded message and AVPs
//     print('Diameter Message:');
//     print('Version: ${message.version}');
//     print('Length: ${message.length}');
//     print('Flags: ${message.flags}');
//     print('Command Code: ${message.commandCode}');
//     print('Application ID: ${message.applicationId}');
//     print('Hop-by-Hop ID: ${message.hopByHopId}');
//     print('End-to-End ID: ${message.endToEndId}');
//     print('AVPs:');
//     for (var avp in message.avps) {
//       print(avp);
//     }
//   } catch (e, st) {
//     print('Error: Failed to decode message: $e');
//     print("Stack trace: $st");
//   }
// }
