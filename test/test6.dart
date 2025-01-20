void main() {
  // Test Re-Auth Request
  final rar = ReAuthRequest(
    originHost: 'client.example.com',
    originRealm: 'example.com',
    destinationRealm: 'server.example.com',
    reAuthRequestType: 1, // Authorize and Authenticate
    sessionId: 'session123',
    userName: 'testuser',
  );

  final rarEncoded = rar.encode();
  print('Encoded RAR: $rarEncoded');

  final rarDecoded = DiameterMessage.decode(rarEncoded);
  print('Decoded RAR: ${rarDecoded.toJson()}');

  // Test Re-Auth Answer
  final raa = ReAuthAnswer(
    originHost: 'server.example.com',
    originRealm: 'example.com',
    resultCode: ResultCodeAVP.DIAMETER_SUCCESS,
    sessionId: 'session123',
    userName: 'testuser',
  );

  final raaEncoded = raa.encode();
  print('Encoded RAA: $raaEncoded');

  final raaDecoded = DiameterMessage.decode(raaEncoded);
  print('Decoded RAA: ${raaDecoded.toJson()}');
}
