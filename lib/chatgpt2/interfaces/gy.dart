import 'interfaces.dart';

class ACRCommand implements GYInterface {
  @override
  int get commandCode => 272; // ACR command code (Accounting Request)

  @override
  void processAccountingRequest(DiameterMessage request) {
    print("Processing ACR command...");
    // Process the ACR request here, validate AVPs, etc.

    // After processing, generate the response
    DiameterMessage response = createAccountingResponse(request);
    sendMessage(response);
  }

  @override
  DiameterMessage createAccountingResponse(DiameterMessage request) {
    // Create a ACA (Accounting Answer) response
    return ACAResponse(request);
  }
}

class ACAResponse extends DiameterMessage {
  ACAResponse(DiameterMessage request)
      : super(
          version: 1,
          commandCode: 273, // ACA command code (Accounting Answer)
          applicationId: 0,
          hopByHopId: request.hopByHopId,
          endToEndId: request.endToEndId,
          avps: [
            ResultCodeAVP(2001), // Example AVP for result code
          ],
        );

  @override
  Uint8List encode() {
    // Implement encoding logic for the ACA response
  }

  @override
  static DiameterMessage decode(Uint8List data) {
    // Implement decoding logic for the ACA response
  }

  @override
  bool validate() {
    // Implement validation logic for the ACA response
  }

  @override
  void processAVPs() {
    // Process the AVPs specific to the ACA response
  }
}
