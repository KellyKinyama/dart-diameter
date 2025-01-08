import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'avp.dart';
import 'header.dart';
import 'message.dart';

class HomeSubscriberServer {
  final String address;
  final int port;
  final Map<String, String> subscriberData = {}; // Simulated subscriber data

  HomeSubscriberServer({
    required this.address,
    required this.port,
  });

  /// Starts the Home Subscriber Server
  Future<void> start() async {
    final server = await ServerSocket.bind(address, port);
    print("Home Subscriber Server started on $address:$port");

    server.listen((Socket client) {
      print("New connection from ${client.remoteAddress}:${client.remotePort}");
      client.listen(
        (data) => _handleRequest(data, client),
        onError: (error) => _handleError(error, client),
        onDone: () => _handleDone(client),
      );
    });
  }

  /// Handles incoming Diameter requests from the Diameter server
  void _handleRequest(Uint8List data, Socket client) {
    try {
      print("Received request from Diameter server: $data");

      // Decode the incoming Diameter message
      final message = DiameterMessage.decode(data);
      print("Decoded DiameterMessage:");
      print("  Version: ${message.header.version}");
      print("  Command Code: ${message.header.commandCode}");
      print("  Application ID: ${message.header.applicationId}");
      print("  Hop-by-Hop ID: ${message.header.hopByHopId}");
      print("  End-to-End ID: ${message.header.endToEndId}");
      print("  AVP Count: ${message.avps.length}");

      // Check for the Authentication Request (AAR)
      if (message.header.commandCode == 258) {
        // AAR Command Code
        _handleAuthenticationRequest(message, client);
      } else {
        _sendErrorResponse(client, "Unknown command code");
      }
    } catch (e, stackTrace) {
      print("Error handling request: $e\n$stackTrace");
      _sendErrorResponse(client, "Error decoding Diameter message");
    }
  }

  /// Handles an Authentication Request (AAR) and validates the user
  void _handleAuthenticationRequest(DiameterMessage request, Socket client) {
    try {
      // Get the AVP (Authentication Data) from the request
      final usernameAVP =
          request.avps.firstWhere((avp) => avp.code == 1, // Code 1 for username
              orElse: () {
        throw Exception("Username AVP not found");
      });

      if (usernameAVP == null) {
        _sendErrorResponse(client, "Username AVP not found");
        return;
      }

      final username = utf8.decode(usernameAVP.value);
      print("Username received: $username");

      // Simulated subscriber data - you can replace this with actual HSS data
      final subscriberPassword = subscriberData[username];

      if (subscriberPassword != null) {
        // Valid user, send an Authentication-Answer (AAA)
        final responseHeader = DiameterHeader(
          version: request.header.version,
          commandFlags: 0x00, // Response flag
          commandCode: request.header.commandCode,
          applicationId: request.header.applicationId,
          hopByHopId: request.header.hopByHopId,
          endToEndId: request.header.endToEndId,
        );

        final responseAVP =
            DiameterAVP.stringAVP(1, "Authentication Successful");
        final responseMessage = DiameterMessage(
          header: responseHeader,
          avps: [responseAVP],
        );

        final encodedResponse = responseMessage.encode();
        client.add(encodedResponse);
        print("Authentication successful, sent response: $encodedResponse");
      } else {
        // Invalid user, send an Authentication Failure response
        _sendErrorResponse(client, "Authentication failed");
      }
    } catch (e) {
      print("Error handling authentication request: $e");
      _sendErrorResponse(client, "Error processing authentication request");
    }
  }

  /// Sends an error response back to the client
  void _sendErrorResponse(Socket client, String errorMessage) {
    final errorHeader = DiameterHeader(
      version: 1,
      commandFlags: 0x00, // Response flag
      commandCode: 299, // Error Command Code (example)
      applicationId: 0,
      hopByHopId: 12345,
      endToEndId: 67890,
    );

    final errorAVP = DiameterAVP.stringAVP(1, errorMessage);
    final errorMessageObj = DiameterMessage(
      header: errorHeader,
      avps: [errorAVP],
    );

    final encodedErrorMessage = errorMessageObj.encode();
    client.add(encodedErrorMessage);
    print("Sent error response: $encodedErrorMessage");
  }

  /// Handles errors during client communication
  void _handleError(error, Socket client) {
    print("Error: $error");
    client.close();
  }

  /// Handles client disconnection
  void _handleDone(Socket client) {
    print("Client disconnected: ${client.remoteAddress}:${client.remotePort}");
    client.close();
  }

  /// Method to simulate subscriber data for testing (username/password pair)
  void addSubscriber(String username, String password) {
    subscriberData[username] = password;
  }
}

void main() async {
  // Create a Home Subscriber Server instance
  final hss = HomeSubscriberServer(address: "127.0.0.1", port: 3869);

  // Simulated subscriber data
  hss.addSubscriber("user1", "password123");
  hss.addSubscriber("user2", "password456");

  // Start the HSS server
  await hss.start();
}
