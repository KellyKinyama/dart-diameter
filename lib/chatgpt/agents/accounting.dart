import 'dart:io';
import 'dart:typed_data';

class DiameterAccountingAgent {
  final String accountingServerAddress;
  final int accountingServerPort;

  DiameterAccountingAgent({required this.accountingServerAddress, required this.accountingServerPort});

  Future<void> handleAccountingMessage(Uint8List data) async {
    final socket = await Socket.connect(accountingServerAddress, accountingServerPort);
    socket.add(data);

    socket.listen(
      (response) => print('Accounting response received: $response'),
      onError: (error) => print('Error handling accounting message: $error'),
      onDone: () => socket.close(),
    );
  }
}
