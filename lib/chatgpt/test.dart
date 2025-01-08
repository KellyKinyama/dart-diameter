// import 'dart:io';

// import 'diameter.dart';

// class DiameterClient {
//   final String host;
//   final int port;
//   late Socket _socket;

//   DiameterClient({required this.host, required this.port});

//   Future<void> connect() async {
//     _socket = await Socket.connect(host, port);
//     _socket.listen((data) {
//       // Handle incoming data
//     });
//   }

//   void sendMessage(DiameterMessage message) {
//     final encodedMessage = message.encode();
//     _socket.add(encodedMessage);
//   }

//   void close() {
//     _socket.close();
//   }
// }

// void main() {
//   final header = DiameterHeader(
//     isRequest: true,
//     isProxiable: false,
//     commandCode: CommandCodes.capabiltyExchange.code,
//     applicationId: 0,
//     hopByHopId: 12345,
//     endToEndId: 67890,
//   );

//   final avp = DiameterAVP(code: 1, value: "Example");

//   final message = DiameterMessage(header: header, avps: [avp]);

//   final client = DiameterClient(host: 'example.com', port: 3868);
//   client.connect().then((_) {
//     client.sendMessage(message);
//   });
// }
