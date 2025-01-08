import 'dart:io';
import 'dart:typed_data';

class DiameterPolicyAgent {
  final String policyServerAddress;
  final int policyServerPort;

  DiameterPolicyAgent(
      {required this.policyServerAddress, required this.policyServerPort});

  Future<void> enforcePolicy(Uint8List data) async {
    final socket = await Socket.connect(policyServerAddress, policyServerPort);
    socket.add(data);

    socket.listen(
      (response) => _handlePolicyResponse(response),
      onError: (error) => print('Error enforcing policy: $error'),
      onDone: () => socket.close(),
    );
  }

  void _handlePolicyResponse(Uint8List data) {
    print('Policy response: $data');
  }
}
