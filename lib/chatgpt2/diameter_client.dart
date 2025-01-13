import 'dart:io';
import 'dart:typed_data';

//import '../base_protocol/diameter_clent.dart';
import 'applications/capabilities_exchange_request.dart';
import 'diameter_message4.dart';

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

    final encodedMessage = message();

    // Encode the CapabilitiesExchangeRequest
    //final encodedMessage = cerRequest.encode();
    socket.listen((data) {
      print("Receive data: $data");
      //final response = DiameterMessage.decode(data);
      //print('Received response with Command Code: ${response.commandCode}');
      socket.destroy();
    });
    print("Sending capabilities exchange request: $encodedMessage");
    socket.add(encodedMessage);
  }
}

void capabilitiesExchangeRequest() {
  // Example: Creating a CapabilitiesExchangeRequest
  // final cerRequest = CapabilitiesExchangeRequest(
  //   sessionId: "1070011400",
  //   originHost: "gx.pcef.example.com",
  //   originRealm: "pcef.example.com",
  //   vendorId: 10415,
  //   originStateId: 219081,
  //   supportedVendorId: 10415,
  //   authApplicationId: 4, // Example: Diameter Credit Control Application
  // );

  // Encode the CapabilitiesExchangeRequest
  // final encodedMessage = cerRequest.encode();
  // return cer;
}

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
