import 'dart:io';

import 'diameter_message.dart';

class DiameterServer {
  final int port;
  //final Map<int, DiameterCommandHandler> commandHandlers = {};

  DiameterServer(this.port) {
    // Register handlers
    // commandHandlers[DiameterCommandCode.CAPABILITIES_EXCHANGE] =
    //     CapabilitiesExchangeHandler();
    // commandHandlers[DiameterCommandCode.DEVICE_WATCHDOG] =
    //     DeviceWatchdogHandler();
    // commandHandlers[DiameterCommandCode.DISCONNECT_PEER] =
    //     DisconnectPeerHandler();
    // commandHandlers[DiameterCommandCode.ACCOUNTING] = AccountingHandler();
  }

  void start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Diameter Server running on port $port');

    server.listen((Socket client) {
      client.listen((data) {
        try {
          final request = DiameterMessage.decode(data);
          print('Received Command Code: ${request.commandCode}');
          //final handler = commandHandlers[request.commandCode];
          // if (handler != null) {
          //   final response = handler.handleRequest(request).encode();
          //   client.add(response);
          // } else {
          //   print('Unsupported Command Code: ${request.commandCode}');
          // }
        } catch (e, stacktrace) {
          print('Failed to decode message: $e');
          print('Stack trace: $stacktrace');
        }
      });
    });
  }
}
