import 'online_charging_client.dart';
import 'online_charging_server.dart';

Future<void> main() async {
  final ocsServer = OnlineChargingServer(3868, '127.0.0.1', 3870);
  ocsServer.start();

//Test with a Client

  final ocsClient = OnlineChargingClient('127.0.0.1', 3868);

  await ocsClient.connect();
  await ocsClient.requestCredit(
      'Session123', 500); // Request 500 units for Session123
  await ocsClient.requestCredit(
      'Session456', 700); // Request 700 units for Session456
  ocsClient.close();
}
