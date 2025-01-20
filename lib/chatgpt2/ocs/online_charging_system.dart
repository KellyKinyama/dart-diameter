import '../interfaces/interfaces.dart';
import 'user_account.dart';

class OnlineChargingSystem implements GXInterface, GYInterface {
  Map<String, UserAccount> userAccounts = {};

  @override
  int get commandCode => 258; // RAR command code for authorization

  @override
  void processAuthorizationRequest(DiameterMessage request) {
    print("Processing RAR command...");
    // Extract user identifier (e.g., from AVPs)
    String userId = getUserIdFromRequest(request);

    // Retrieve user account
    UserAccount? userAccount = userAccounts[userId];

    if (userAccount == null) {
      // User not found, reject the request
      DiameterMessage response = createAuthorizationResponse(request, 5000); // DIAMETER_AUTHENTICATION_REJECTED
      sendMessage(response);
      return;
    }

    // Perform balance check and authorization logic
    if (!userAccount.hasSufficientBalance(5.0)) {  // Example: service requires 5.0 units
      // Insufficient balance, reject the request
      DiameterMessage response = createAuthorizationResponse(request, 5001); // DIAMETER_INSUFFICIENT_BALANCE
      sendMessage(response);
      return;
    }

    // If authorized, deduct the balance and send success response
    userAccount.deductBalance(5.0);
    DiameterMessage response = createAuthorizationResponse(request, 2001); // DIAMETER_SUCCESS
    sendMessage(response);
  }

  @override
  DiameterMessage createAuthorizationResponse(DiameterMessage request, int resultCode) {
    return RAAResponse(request, resultCode);
  }

  @override
  int get accountingCommandCode => 272; // ACR command code for accounting

  @override
  void processAccountingRequest(DiameterMessage request) {
    print("Processing ACR command...");
    // Extract user identifier and service usage details
    String userId = getUserIdFromRequest(request);
    double serviceCharge = getServiceChargeFromRequest(request);  // Example: service charge from AVP

    // Retrieve user account
    UserAccount? userAccount = userAccounts[userId];

    if (userAccount == null) {
      // User not found, reject the request
      DiameterMessage response = createAccountingResponse(request, 5000); // DIAMETER_AUTHENTICATION_REJECTED
      sendMessage(response);
      return;
    }

    // Perform balance check
    if (!userAccount.hasSufficientBalance(serviceCharge)) {
      // Insufficient balance, reject the request
      DiameterMessage response = createAccountingResponse(request, 5001); // DIAMETER_INSUFFICIENT_BALANCE
      sendMessage(response);
      return;
    }

    // Deduct balance based on service usage
    userAccount.deductBalance(serviceCharge);

    // Create accounting response and send
    DiameterMessage response = createAccountingResponse(request, 2001); // DIAMETER_SUCCESS
    sendMessage(response);
  }

  @override
  DiameterMessage createAccountingResponse(DiameterMessage request, int resultCode) {
    return ACAResponse(request, resultCode);
  }

  // Helper functions to extract data from the request
  String getUserIdFromRequest(DiameterMessage request) {
    // Extract the user ID from the AVP or message
    return "user123"; // Example, should extract from actual AVPs
  }

  double getServiceChargeFromRequest(DiameterMessage request) {
    // Extract the service charge from the AVP or message
    return 5.0; // Example service charge amount
  }

  @override
  void sendMessage(DiameterMessage message) {
    // Logic to send the message over the network
    print("Sending message: ${message.commandCode}");
  }
}
