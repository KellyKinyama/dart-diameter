import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'avp.dart';
import 'header.dart';
import 'message.dart';

class DiameterServer {
  final String address;
  final int port;

  DiameterServer({required this.address, required this.port});

  /// Starts the Diameter server
  Future<void> start() async {
    final server = await ServerSocket.bind(address, port);
    print("Diameter server started on $address:$port");

    server.listen((Socket client) {
      print("New connection from ${client.remoteAddress}:${client.remotePort}");
      client.listen(
        (data) => _handleRequest(data, client),
        onError: (error) => _handleError(error, client),
        onDone: () => _handleDone(client),
        cancelOnError: true, // Automatically cancel on error
      );
    });
  }

  /// Handles incoming requests
  void _handleRequest(Uint8List data, Socket client) {
    try {
      print("Received data: $data");

      // Decode the incoming Diameter message
      final message = DiameterMessage.decode(data);
      print("Decoded DiameterMessage:");
      print("  Version: ${message.header.version}");
      print("  Command Code: ${message.header.commandCode}");
      print("  Application ID: ${message.header.applicationId}");
      print("  Hop-by-Hop ID: ${message.header.hopByHopId}");
      print("  End-to-End ID: ${message.header.endToEndId}");
      print("  AVP Count: ${message.avps.length}");

      // Handle AVPs in the message
      for (var avp in message.avps) {
        print("  AVP Code: ${avp.code}");
        print("  Flags: ${avp.flags}");
        print("  Value Length: ${avp.value.length}");
        if (avp.code == 1) {
          print("  Value (String): ${utf8.decode(avp.value)}");
        } else if (avp.code == 2) {
          final intValue =
              ByteData.sublistView(avp.value).getUint32(0, Endian.big);
          print("  Value (Integer): $intValue");
        }
      }

      // Create a response Diameter message
      final responseHeader = DiameterHeader(
        version: message.header.version,
        commandFlags: 0x00, // Response flag
        commandCode: message.header.commandCode,
        applicationId: message.header.applicationId,
        hopByHopId: message.header.hopByHopId,
        endToEndId: message.header.endToEndId,
      );

      final responseAVP = DiameterAVP.stringAVP(1, "Response AVP");
      final responseMessage = DiameterMessage(
        header: responseHeader,
        avps: [responseAVP],
      );

      // Encode and send the response
      final encodedResponse = responseMessage.encode();
      client.add(encodedResponse);
      print("Response sent: $encodedResponse");
    } catch (e, stackTrace) {
      print("Error handling request: $e\n$stackTrace");
      _sendErrorResponse(client, "Error decoding Diameter message");
    }
  }

  /// Sends an error response back to the client
  void _sendErrorResponse(Socket client, String errorMessage) {
    final errorHeader = DiameterHeader(
      version: 1,
      commandFlags: 0x00, // Response flag
      commandCode: 500, // Typically error-related command code
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
}

void main() async {
  final server = DiameterServer(address: "127.0.0.1", port: 3868);
  await server.start();
}
