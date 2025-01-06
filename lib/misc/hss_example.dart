import 'package:dart_diameter/misc/hss_client.dart';
import 'package:dart_diameter/misc/hss_server.dart';

Future<void> main() async {
  final server = HssServer(3868);
  await server.start();

  // Delay to ensure the server is ready
  await Future.delayed(Duration(seconds: 1));

  final client = HssClient('127.0.0.1', 3868);
  await client.sendAir('001010000000001');
}
