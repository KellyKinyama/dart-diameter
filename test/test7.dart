void testMissingMandatoryAvp() {
  try {
    final invalidRar = DiameterMessage(
      version: 1,
      flags: 0x80,
      commandCode: 258,
      applicationId: 0,
      hopByHopId: 12345,
      endToEndId: 67890,
      avps: [], // No AVPs
    );
    ReAuthRequest.fromDecoded(invalidRar);
  } catch (e) {
    print(e); // Should print a DiameterProtocolException with missing AVP info
  }
}

void testInvalidAvpValue() {
  try {
    final invalidRar = DiameterMessage(
      version: 1,
      flags: 0x80,
      commandCode: 258,
      applicationId: 0,
      hopByHopId: 12345,
      endToEndId: 67890,
      avps: [
        SessionIdAVP('session123'),
        ReAuthRequestTypeAVP(5), // Invalid value
      ],
    );
    ReAuthRequest.fromDecoded(invalidRar);
  } catch (e) {
    print(
        e); // Should print a DiameterProtocolException with invalid AVP value info
  }
}

void testErrorResponse() {
  final errorResponse = ReAuthAnswer(
    originHost: 'server.example.com',
    originRealm: 'example.com',
    resultCode: ResultCodeAVP.DIAMETER_AUTHENTICATION_REJECTED,
    sessionId: 'session123',
    errorMessage: 'Re-authorization failed due to invalid credentials',
  );

  final encoded = errorResponse.encode();
  final decoded = DiameterMessage.decode(encoded);

  print('Decoded Error Response: ${decoded.toJson()}');
}
