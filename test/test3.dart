void main() {
  // Test CER
  final cer = CapabilitiesExchangeRequest(
    originHost: 'example.com',
    originRealm: 'example.com',
    vendorId: 10415,
    supportedVendorIds: [10415, 12345],
    authAppIds: [1, 2],
    acctAppIds: [3],
  );

  final cerEncoded = cer.encode();
  print('Encoded CER: $cerEncoded');

  final cerDecoded = DiameterMessage.decode(cerEncoded);
  print('Decoded CER: ${cerDecoded.toJson()}');

  // Test CEA
  final cea = CapabilitiesExchangeAnswer(
    originHost: 'peer.com',
    originRealm: 'peer.com',
    resultCode: ResultCodeAVP.DIAMETER_SUCCESS,
  );

  final ceaEncoded = cea.encode();
  print('Encoded CEA: $ceaEncoded');

  final ceaDecoded = DiameterMessage.decode(ceaEncoded);
  print('Decoded CEA: ${ceaDecoded.toJson()}');
}
