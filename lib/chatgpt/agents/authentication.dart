import 'dart:io';
import 'dart:typed_data';

class DiameterAuthenticationAgent {
  final String authServerAddress;
  final int authServerPort;

  DiameterAuthenticationAgent(
      {required this.authServerAddress, required this.authServerPort});

  Future<void> authenticateUser(Uint8List data) async {
    final socket = await Socket.connect(authServerAddress, authServerPort);
    socket.add(data);

    socket.listen(
      (response) => _handleAuthenticationResponse(response),
      onError: (error) => print('Error authenticating user: $error'),
      onDone: () => socket.close(),
    );
  }

  void _handleAuthenticationResponse(Uint8List data) {
    print('Authentication response received: $data');
  }
}
