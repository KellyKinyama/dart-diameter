import 'interfaces.dart';

class RARCommand implements GXInterface {
  @override
  int get commandCode => 258; // RAR command code (Authorization Request)

  @override
  void processAuthorizationRequest(DiameterMessage request) {
    print("Processing RAR command...");
    // Process the RAR request here, validate AVPs, etc.

    // After processing, generate the response
    DiameterMessage response = createAuthorizationResponse(request);
    sendMessage(response);
  }

  @override
  DiameterMessage createAuthorizationResponse(DiameterMessage request) {
    // Create a RAA (Authorization Answer) response
    return RAAResponse(request);
  }
}

class RAAResponse extends DiameterMessage {
  RAAResponse(DiameterMessage request)
      : super(
          version: 1,
          commandCode: 259, // RAA command code (Authorization Answer)
          applicationId: 0,
          hopByHopId: request.hopByHopId,
          endToEndId: request.endToEndId,
          avps: [
            ResultCodeAVP(2001), // Example AVP for result code
          ],
        );

  @override
  Uint8List encode() {
    // Implement encoding logic for the RAA response
  }

  @override
  static DiameterMessage decode(Uint8List data) {
    // Implement decoding logic for the RAA response
  }

  @override
  bool validate() {
    // Implement validation logic for the RAA response
  }

  @override
  void processAVPs() {
    // Process the AVPs specific to the RAA response
  }
}
