void main() {
  // Test ACR
  final acr = AccountingRequest(
    originHost: 'example.com',
    originRealm: 'example.com',
    sessionId: 'session123',
    accountingRecordType: 1, // START
    accountingRecordNumber: 42,
  );

  final acrEncoded = acr.encode();
  print('Encoded ACR: $acrEncoded');

  final acrDecoded = DiameterMessage.decode(acrEncoded);
  print('Decoded ACR: ${acrDecoded.toJson()}');

  // Test ACA
  final aca = AccountingAnswer(
    originHost: 'peer.com',
    originRealm: 'peer.com',
    sessionId: 'session123',
    resultCode: ResultCodeAVP.DIAMETER_SUCCESS,
  );

  final acaEncoded = aca.encode();
  print('Encoded ACA: $acaEncoded');

  final acaDecoded = DiameterMessage.decode(acaEncoded);
  print('Decoded ACA: ${acaDecoded.toJson()}');

  // Test AAR
  final aar = AuthenticationRequest(
    originHost: 'example.com',
    originRealm: 'example.com',
    destinationRealm: 'peer.com',
    userName: 'testuser',
  );

  final aarEncoded = aar.encode();
  print('Encoded AAR: $aarEncoded');

  final aarDecoded = DiameterMessage.decode(aarEncoded);
  print('Decoded AAR: ${aarDecoded.toJson()}');

  // Test AAA
  final aaa = AuthenticationAnswer(
    originHost: 'peer.com',
    originRealm: 'peer.com',
    resultCode: ResultCodeAVP.DIAMETER_SUCCESS,
    userName: 'testuser',
  );

  final aaaEncoded = aaa.encode();
  print('Encoded AAA: $aaaEncoded');

  final aaaDecoded = DiameterMessage.decode(aaaEncoded);
  print('Decoded AAA: ${aaaDecoded.toJson()}');
}
