import 'dart:io';
import 'dart:typed_data';

class DiameterProxyAgent {
  final String serverAddress;
  final int serverPort;

  DiameterProxyAgent({required this.serverAddress, required this.serverPort});

  Future<void> forwardRequest(Uint8List data) async {
    final socket = await Socket.connect(serverAddress, serverPort);
    socket.add(data);

    socket.listen(
      (response) => _handleServerResponse(response),
      onError: (error) => print('Error forwarding request: $error'),
      onDone: () => socket.close(),
    );
  }

  void _handleServerResponse(Uint8List data) {
    print('Forwarded response: $data');
  }
}
