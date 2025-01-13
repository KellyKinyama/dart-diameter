import 'dart:io';
import '../applications/capabilities_exchange_answer2.dart';
import '../diameter_message8.dart';

class DiameterServer {
  final int port;
  // final Map<int, DiameterCommandHandler> commandHandlers = {};

  DiameterServer(this.port) {
    // Register handlers (if needed in the future)
    // commandHandlers[DiameterCommandCode.CAPABILITIES_EXCHANGE] =
    //     CapabilitiesExchangeHandler();
  }

  void start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
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

            final cea = CapabilitiesExchangeAnswer(
              resultCode: 2001, // Example Result Code: Success
              originHost: 'example.com',
              originRealm: 'example.com',
              vendorId: 10415, // Example Vendor ID
              productName: 'Diameter Server',
              hopByHopId: request.hopByHopId,
              endToEndId: request.endToEndId,
            );

            // Encode and print the CEA
            final ceaEncoded = cea.encode();

            // Optionally print response for debugging
            // print("Sending Capabilities Exchange Answer: $ceaEncoded");
            final message = DiameterMessage.decode(ceaEncoded);

            // Send the CEA response to the client
            client.add(ceaEncoded);
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
  final server = DiameterServer(3868); // Standard DIAMETER port
  server.start();

  // Delay to ensure the server is ready
  await Future.delayed(Duration(seconds: 1));

  // Uncomment this if you want to start a client to test the server
  // final client = DiameterClient('127.0.0.1', 3868);
  // client.sendRequest();
}
