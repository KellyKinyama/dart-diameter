import 'dart:io';
import '../applications/capabilities_exchange_answer2.dart';
import '../diameter_message11.dart';

class DiameterServer {
  final int port;
  final String ipAdress;
  // final Map<int, DiameterCommandHandler> commandHandlers = {};

  DiameterServer(this.ipAdress, this.port) {
    // Register handlers (if needed in the future)
    // commandHandlers[DiameterCommandCode.CAPABILITIES_EXCHANGE] =
    //     CapabilitiesExchangeHandler();
  }

  void start() async {
    final server = await ServerSocket.bind(InternetAddress(ipAdress), port);
    print('Diameter Server running on port $port');

    server.listen((Socket client) {
      client.listen((data) async {
        try {
          // Decode the incoming Diameter message
          final request = DiameterMessage.decode(data);
          print("Request: $request");
          print('Received Command Code: ${request.commandCode}');

          // Handle Capabilities Exchange Request (CER)
          if (request.commandCode == 257) {
            // Assuming cert_test_answer is a predefined byte array for Capabilities Exchange Answer

            // final cea = CapabilitiesExchangeAnswer(
            //   resultCode: 2001, // Example Result Code: Success
            //   originHost: 'example.com',
            //   originRealm: 'example.com',
            //   vendorId: 10415, // Example Vendor ID
            //   productName: 'Diameter Server',
            //   hopByHopId: request.hopByHopId,
            //   endToEndId: request.endToEndId,
            // );

            final dm = DiameterMessage.fromFields(
                version: 1,
                length: 160,
                flags: 0,
                commandCode: 257,
                applicationId: 0,
                hopByHopId: 1470542647,
                endToEndId: 4122139619,
                apvs: [
                  AVP(263, 64, 18, [49, 51, 52, 57, 51, 52, 56, 53, 57, 57]),
                  AVP(268, 64, 12, [0, 0, 7, 209]),
                  AVP(264, 96, 16, [116, 101, 115, 116, 46, 99, 111, 109]),
                  AVP(296, 64, 11, [99, 111, 109]),
                  AVP(257, 96, 26, [
                    0,
                    2,
                    32,
                    1,
                    13,
                    184,
                    51,
                    18,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1
                  ]),
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

            // Encode and print the CEA
            final ceaEncoded = dm.encode();

            // Optionally print response for debugging
            // print("Sending Capabilities Exchange Answer: $ceaEncoded");
            //final message = DiameterMessage.decode(ceaEncoded);

            // Send the CEA response to the client
            // client.add(ceaEncoded);
            client.add(cea_test);
            await client.flush();
            print("Response sent.");
          } else {
            print('Unsupported Command Code: ${request.commandCode}');
            // Handle other command codes here if needed
          }
        } catch (e, stacktrace) {
          print('Failed to decode message: $e');
          print('Stack trace: $stacktrace');
        }
      });
    });
  }
}

Future<void> main() async {
  final server = DiameterServer("127.0.0.1", 3868); // Standard DIAMETER port
  server.start();

  // Delay to ensure the server is ready
  await Future.delayed(Duration(seconds: 1));

  // Uncomment this if you want to start a client to test the server
  // final client = DiameterClient('127.0.0.1', 3868);
  // client.sendRequest();
}
