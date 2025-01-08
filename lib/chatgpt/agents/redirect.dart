import 'dart:io';
import 'dart:typed_data';

class DiameterRedirectAgent {
  final String redirectAddress;
  final int redirectPort;

  DiameterRedirectAgent(
      {required this.redirectAddress, required this.redirectPort});

  Future<void> redirectRequest(Uint8List data) async {
    final socket = await Socket.connect(redirectAddress, redirectPort);
    print("Redirecting to $redirectAddress:$redirectPort");

    socket.add(data);

    socket.listen(
      (response) => _handleResponse(response),
      onError: (error) => print('Error redirecting request: $error'),
      onDone: () => socket.close(),
    );
  }

  void _handleResponse(Uint8List data) {
    print("Redirected response: $data");
  }
}
