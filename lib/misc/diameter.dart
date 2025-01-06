import 'package:dart_diameter/misc/client.dart';
import 'package:dart_diameter/misc/server.dart';

Future<void> main() async {
  final server = DiameterServer(3868);
  server.start();

  // Allow the server to start before running the client
  await Future.delayed(Duration(seconds: 1));

  final client = DiameterClient('127.0.0.1', 3868);
  client.sendCer();
}
