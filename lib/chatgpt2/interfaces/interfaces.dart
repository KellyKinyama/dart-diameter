abstract class ROInterface {
  int get commandCode; // Command code for RO-related commands

  // Method to process an RO request
  void processRORequest(DiameterMessage request);

  // Method to generate a response for the RO request
  DiameterMessage createROResponse(DiameterMessage request);
}
abstract class GXInterface {
  int get commandCode; // Command code for GX-related commands

  // Method to process an authorization request (e.g., RAR)
  void processAuthorizationRequest(DiameterMessage request);

  // Method to generate a response for the authorization request (e.g., RAA)
  DiameterMessage createAuthorizationResponse(DiameterMessage request);
}

abstract class GYInterface {
  int get commandCode; // Command code for GY-related commands

  // Method to process an accounting request (e.g., ACR)
  void processAccountingRequest(DiameterMessage request);

  // Method to generate a response for the accounting request (e.g., ACA)
  DiameterMessage createAccountingResponse(DiameterMessage request);
}
