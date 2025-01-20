import 'dart:io';
import 'dart:typed_data';

//import '../base_protocol/diameter_clent.dart';
//import 'applications/capabilities_exchange_request.dart';
import 'cer.dart';
import 'diameter_message.dart';
import 'tests.dart';

Uint8List message() {
  // final diameterMessage = DiameterMessage(
  //   version: 1,
  //   flags: 128,
  //   commandCode: 257,
  //   applicationId: 0,
  //   hopByHopId: 1470542647,
  //   endToEndId: 4122139619,
  //   avps: [
  //     AVP(code: 263, data: [49, 51, 52, 57, 51, 52, 56, 53, 57, 57]),
  //     AVP(code: 264, data: [
  //       103,
  //       120,
  //       46,
  //       112,
  //       99,
  //       101,
  //       102,
  //       46,
  //       101,
  //       120,
  //       97,
  //       109,
  //       112,
  //       108,
  //       101,
  //       46,
  //       99,
  //       111,
  //       109
  //     ]),
  //     AVP(code: 296, data: [
  //       112,
  //       99,
  //       101,
  //       102,
  //       46,
  //       101,
  //       120,
  //       97,
  //       109,
  //       112,
  //       108,
  //       101,
  //       46,
  //       99,
  //       111,
  //       109
  //     ]),
  //     AVP(code: 266, data: [0, 0, 40, 175]),
  //     AVP(code: 278, data: [0, 3, 87, 201]),
  //     AVP(code: 265, data: [0, 0, 40, 175]),
  //     AVP(code: 258, data: [0, 0, 0, 4]),
  //   ],
  // );

  // // Encode the Diameter message
  // final encodedMessage = diameterMessage.encode();
  // print('Encoded Diameter Message: ${encodedMessage}');
  // return encodedMessage;

  return cer;
}

class DiameterClient {
  final String host;
  final int port;

  DiameterClient(this.host, this.port);

  void sendRequest() async {
    final socket = await Socket.connect(host, port);
    print('Connected to Diameter Server');

    // final cerRequest = CapabilitiesExchangeRequest(
    //   sessionId: "1070011400",
    //   originHost: "gx.pcef.example.com",
    //   originRealm: "pcef.example.com",
    //   vendorId: 10415,
    //   originStateId: 219081,
    //   supportedVendorId: 10415,
    //   authApplicationId: 4, // Example: Diameter Credit Control Application
    // );

    //final encodedMessage = message();

    // Encode the CapabilitiesExchangeRequest
    //final encodedMessage = cerRequest.encode();
    socket.listen((data) {
      //print("Receive data: $data");
      final response = DiameterMessage.decode(data);
      //print('Received response with Command Code: ${response.commandCode}');

      //Flags: 128 (Typically means the message is a request)
      if (response.flags == 128) {
        print("message is request with flags: ${response.flags}");
        print("Request ${DiameterMessage.decode(data)}");
        final req = DiameterMessage.decode(data);
        print(
            "Sending message response with flags: ${response.flags},with Command Code: ${response.commandCode}");
        final resp = DiameterMessage.fromFields(
            version: req.version,
            flags: 0,
            commandCode: req.commandCode,
            applicationId: 0,
            hopByHopId: req.hopByHopId,
            endToEndId: req.endToEndId,
            avpList: [
              AVP(263, 64, 18, [49, 51, 52, 57, 51, 52, 56, 53, 57, 57]),
              AVP(268, 64, 12, [0, 0, 7, 209]),
              AVP(264, 96, 16, [116, 101, 115, 116, 46, 99, 111, 109]),
              AVP(296, 64, 11, [99, 111, 109]),
              AVP(257, 96, 26,
                  [0, 2, 32, 1, 13, 184, 51, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]),
              AVP(257, 96, 14, [0, 1, 1, 2, 3, 4]),
              AVP(266, 96, 12, [0, 0, 0, 123]),
              AVP(269, 0, 21, [
                110,
                111,
                100,
                101,
                45,
                100,
                105,
                97,
                109,
                101,
                116,
                101,
                114
              ])
            ]);
        print(DiameterMessage.decode(cea));
        socket.add(resp.encode());
      }
      //Flags: 0 (Typically indicates a response message)
      else if (response.flags == 0) {
        print(
            "message response with flags: ${response.flags},with Command Code: ${response.commandCode}");
        // print("Received: $data");
      }
      //socket.destroy();
    });
    //print("Sending capabilities exchange request: $cer");
    final dm = DiameterMessage.fromFields(
        version: 1,
        // length: 124,
        flags: 128,
        commandCode: 257,
        applicationId: 0,
        hopByHopId: 57937898,
        endToEndId: 2255810703,
        avpList: [
          AVP(263, 64, 18, [51, 52, 52, 51, 49, 51, 51, 50, 50, 48]),
          AVP(264, 96, 19, [103, 120, 46, 112, 99, 101, 102, 46, 99, 111, 109]),
          AVP(296, 64, 16, [112, 99, 101, 102, 46, 99, 111, 109]),
          AVP(266, 96, 12, [0, 0, 40, 175]),
          AVP(278, 64, 12, [0, 3, 87, 201]),
          AVP(265, 96, 12, [0, 0, 40, 175]),
          AVP(258, 64, 12, [0, 0, 0, 4]),
        ]);
    //final request = DiameterMessage.decode(cer);
    //print('Sending request with Command Code: ${request.commandCode}');
    // if (request.flags == 128) {
    //   print("message is request");
    // }
    final encodedMsg = dm.encode();
    // print(encodedMsg);
    // print(DiameterMessage.decode(cer));

    socket.add(encodedMsg);
  }

  void sendRequestWithMessage(DiameterMessage message) async {
    final socket = await Socket.connect(host, port);
    print('Connected to Diameter Server');
    socket.listen((data) {
      final response = DiameterMessage.decode(data);
      print('Received response with Command Code: ${response.commandCode}');
      print("CCA: ${response}");
      // Handle responses here
    });

    final encodedMessage = message.encode();
    // print('Sending Diameter Message: $encodedMessage');
    socket.add(encodedMessage);
  }
}

// void capabilitiesExchangeRequest() {
//   // Example: Creating a CapabilitiesExchangeRequest
//   // final cerRequest = CapabilitiesExchangeRequest(
//   //   sessionId: "1070011400",
//   //   originHost: "gx.pcef.example.com",
//   //   originRealm: "pcef.example.com",
//   //   vendorId: 10415,
//   //   originStateId: 219081,
//   //   supportedVendorId: 10415,
//   //   authApplicationId: 4, // Example: Diameter Credit Control Application
//   // );

//   // Encode the CapabilitiesExchangeRequest
//   // final encodedMessage = cerRequest.encode();
//   // return cer;
// }

void main() {
  final client = DiameterClient('127.0.0.1', 3868);
  client.sendRequest();
}

final cer = Uint8List.fromList([
  1,
  0,
  0,
  140,
  128,
  0,
  1,
  1,
  0,
  0,
  0,
  0,
  87,
  166,
  179,
  55,
  245,
  178,
  219,
  227,
  0,
  0,
  1,
  7,
  64,
  0,
  0,
  18,
  49,
  51,
  52,
  57,
  51,
  52,
  56,
  53,
  57,
  57,
  0,
  0,
  0,
  0,
  1,
  8,
  96,
  0,
  0,
  27,
  103,
  120,
  46,
  112,
  99,
  101,
  102,
  46,
  101,
  120,
  97,
  109,
  112,
  108,
  101,
  46,
  99,
  111,
  109,
  0,
  0,
  0,
  1,
  40,
  64,
  0,
  0,
  24,
  112,
  99,
  101,
  102,
  46,
  101,
  120,
  97,
  109,
  112,
  108,
  101,
  46,
  99,
  111,
  109,
  0,
  0,
  1,
  10,
  96,
  0,
  0,
  12,
  0,
  0,
  40,
  175,
  0,
  0,
  1,
  22,
  64,
  0,
  0,
  12,
  0,
  3,
  87,
  201,
  0,
  0,
  1,
  9,
  96,
  0,
  0,
  12,
  0,
  0,
  40,
  175,
  0,
  0,
  1,
  2,
  64,
  0,
  0,
  12,
  0,
  0,
  0,
  4
]);
