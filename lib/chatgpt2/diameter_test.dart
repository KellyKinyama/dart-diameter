import 'diameter_server.dart';

Future<void> main() async {
  final server = DiameterServer(3868); // Standard DIAMETER port
  server.start();

  // Delay to ensure the server is ready
//   await Future.delayed(Duration(seconds: 1));
// //Start the Client

//   final client = DiameterClient('127.0.0.1', 3868);
//   client.sendRequest();
}
