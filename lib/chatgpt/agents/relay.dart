import 'dart:io';
import 'dart:typed_data';

class DiameterRelayAgent {
  final String targetAddress;
  final int targetPort;

  DiameterRelayAgent({required this.targetAddress, required this.targetPort});

  Future<void> relayMessage(Uint8List data) async {
    final socket = await Socket.connect(targetAddress, targetPort);
    socket.add(data);

    socket.listen(
      (response) => print('Relayed response: $response'),
      onError: (error) => print('Error relaying message: $error'),
      onDone: () => socket.close(),
    );
  }
}
