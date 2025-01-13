// import 'dart:typed_data';
// import 'dart:convert';

// class CapabilitiesExchangeRequest {
//   final String sessionId;
//   final String originHost;
//   final String originRealm;
//   final int vendorId;
//   final int originStateId;
//   final int supportedVendorId;
//   final int authApplicationId;

//   CapabilitiesExchangeRequest({
//     required this.sessionId,
//     required this.originHost,
//     required this.originRealm,
//     required this.vendorId,
//     required this.originStateId,
//     required this.supportedVendorId,
//     required this.authApplicationId,
//   });

//   // Decode a Capabilities-Exchange-Request message
//   static CapabilitiesExchangeRequest decode(Uint8List data) {
//     int offset = 0;

//     String sessionId = _decodeString(data, offset);
//     offset += sessionId.length + 2;
//     String originHost = _decodeString(data, offset);
//     offset += originHost.length + 2;
//     String originRealm = _decodeString(data, offset);
//     offset += originRealm.length + 2;

//     int vendorId = ByteData.sublistView(data, offset).getUint32(0, Endian.big);
//     offset += 4;
//     int originStateId =
//         ByteData.sublistView(data, offset).getUint32(0, Endian.big);
//     offset += 4;
//     int supportedVendorId =
//         ByteData.sublistView(data, offset).getUint32(0, Endian.big);
//     offset += 4;
//     int authApplicationId =
//         ByteData.sublistView(data, offset).getUint32(0, Endian.big);

//     return CapabilitiesExchangeRequest(
//       sessionId: sessionId,
//       originHost: originHost,
//       originRealm: originRealm,
//       vendorId: vendorId,
//       originStateId: originStateId,
//       supportedVendorId: supportedVendorId,
//       authApplicationId: authApplicationId,
//     );
//   }

//   // Encode the Capabilities-Exchange-Request into a byte array
//   Uint8List encode() {
//     final List<int> bytes = [];

//     // Encode sessionId
//     bytes.addAll(_encodeString(sessionId));

//     // Encode originHost
//     bytes.addAll(_encodeString(originHost));

//     // Encode originRealm
//     bytes.addAll(_encodeString(originRealm));

//     // Encode vendorId
//     bytes.addAll(_encodeUInt32(vendorId));

//     // Encode originStateId
//     bytes.addAll(_encodeUInt32(originStateId));

//     // Encode supportedVendorId
//     bytes.addAll(_encodeUInt32(supportedVendorId));

//     // Encode authApplicationId
//     bytes.addAll(_encodeUInt32(authApplicationId));

//     return Uint8List.fromList(bytes);
//   }

//   // Helper function to decode a string from the byte array
//   static String _decodeString(Uint8List data, int offset) {
//     int length = ByteData.sublistView(data, offset).getUint16(0, Endian.big);
//     return utf8.decode(data.sublist(offset + 2, offset + 2 + length));
//   }

//   // Helper function to encode a string into the byte array
//   List<int> _encodeString(String value) {
//     List<int> encoded = utf8.encode(value);
//     List<int> lengthBytes = _encodeUInt16(encoded.length);
//     return lengthBytes + encoded;
//   }

//   // Helper function to encode an unsigned 16-bit integer
//   List<int> _encodeUInt16(int value) {
//     final buffer = ByteData(2);
//     buffer.setUint16(0, value, Endian.big);
//     return buffer.buffer.asUint8List();
//   }

//   // Helper function to encode an unsigned 32-bit integer
//   List<int> _encodeUInt32(int value) {
//     final buffer = ByteData(4);
//     buffer.setUint32(0, value, Endian.big);
//     return buffer.buffer.asUint8List();
//   }
// }

// void main() {
//   // Example: Creating a CapabilitiesExchangeRequest
//   final cerRequest = CapabilitiesExchangeRequest(
//     sessionId: "1070011400",
//     originHost: "gx.pcef.example.com",
//     originRealm: "pcef.example.com",
//     vendorId: 10415,
//     originStateId: 219081,
//     supportedVendorId: 10415,
//     authApplicationId: 4, // Example: Diameter Credit Control Application
//   );

//   // Encode the CapabilitiesExchangeRequest
//   final encodedMessage = cerRequest.encode();
//   print('Encoded Capabilities-Exchange-Request: $encodedMessage');

//   // Decode the message
//   final decodedMessage = CapabilitiesExchangeRequest.decode(encodedMessage);
//   print('Decoded Capabilities-Exchange-Request:');
//   print('Session-Id: ${decodedMessage.sessionId}');
//   print('Origin-Host: ${decodedMessage.originHost}');
//   print('Origin-Realm: ${decodedMessage.originRealm}');
//   print('Vendor-Id: ${decodedMessage.vendorId}');
//   print('Origin-State-Id: ${decodedMessage.originStateId}');
//   print('Supported-Vendor-Id: ${decodedMessage.supportedVendorId}');
//   print('Auth-Application-Id: ${decodedMessage.authApplicationId}');
// }
