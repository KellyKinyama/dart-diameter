import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'commands/accounting.dart';
import 'commands/capabilites_exchange.dart';
import 'commands/command_code.dart';
import 'commands/device_watchdog.dart';
import 'commands/disconnect_peer.dart';
import 'commands/handler.dart';
import 'diameter_avp.dart';
import 'diameter_message.dart';

class DiameterServer {
  final int port;
  final Map<int, DiameterCommandHandler> commandHandlers = {};

  DiameterServer(this.port) {
    // Register handlers
    commandHandlers[DiameterCommandCode.CAPABILITIES_EXCHANGE] =
        CapabilitiesExchangeHandler();
    commandHandlers[DiameterCommandCode.DEVICE_WATCHDOG] =
        DeviceWatchdogHandler();
    commandHandlers[DiameterCommandCode.DISCONNECT_PEER] =
        DisconnectPeerHandler();
    commandHandlers[DiameterCommandCode.ACCOUNTING] = AccountingHandler();
  }

  void start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Diameter Server running on port $port');

    server.listen((Socket client) {
      client.listen((data) {
        try {
          final request = DiameterMessage.decode(data);
          print('Received Command Code: ${request.commandCode}');
          final handler = commandHandlers[request.commandCode];
          if (handler != null) {
            final response = handler.handleRequest(request).encode();
            client.add(response);
          } else {
            print('Unsupported Command Code: ${request.commandCode}');
          }
        } catch (e, stacktrace) {
          print('Failed to decode message: $e');
          print('Stack trace: $stacktrace');
        }
      });
    });
  }
}
