void main() {
  // Test DWR
  final dwr = DeviceWatchdogRequest(
    originHost: 'example.com',
    originRealm: 'example.com',
  );

  final dwrEncoded = dwr.encode();
  print('Encoded DWR: $dwrEncoded');

  final dwrDecoded = DiameterMessage.decode(dwrEncoded);
  print('Decoded DWR: ${dwrDecoded.toJson()}');

  // Test DWA
  final dwa = DeviceWatchdogAnswer(
    originHost: 'peer.com',
    originRealm: 'peer.com',
    resultCode: ResultCodeAVP.DIAMETER_SUCCESS,
  );

  final dwaEncoded = dwa.encode();
  print('Encoded DWA: $dwaEncoded');

  final dwaDecoded = DiameterMessage.decode(dwaEncoded);
  print('Decoded DWA: ${dwaDecoded.toJson()}');

  // Test DPR
  final dpr = DisconnectPeerRequest(
    originHost: 'example.com',
    originRealm: 'example.com',
    disconnectCause: DisconnectCauseAVP.DO_NOT_WANT_TO_TALK_TO_YOU,
  );

  final dprEncoded = dpr.encode();
  print('Encoded DPR: $dprEncoded');

  final dprDecoded = DiameterMessage.decode(dprEncoded);
  print('Decoded DPR: ${dprDecoded.toJson()}');

  // Test DPA
  final dpa = DisconnectPeerAnswer(
    originHost: 'peer.com',
    originRealm: 'peer.com',
    resultCode: ResultCodeAVP.DIAMETER_SUCCESS,
  );

  final dpaEncoded = dpa.encode();
  print('Encoded DPA: $dpaEncoded');

  final dpaDecoded = DiameterMessage.decode(dpaEncoded);
  print('Decoded DPA: ${dpaDecoded.toJson()}');
}
