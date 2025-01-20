import 'dart:typed_data';
import 'dart:convert';
import './diameter_message.dart';

void main() {
  // Authentication Request (AIR)
  final airRequest = DiameterMessage.fromFields(
    version: 1,
    commandCode: 274, // Command Code for AIR
    applicationId: 4, // Diameter Credit Control Application
    hopByHopId: 12348, // Unique value for this request
    endToEndId: 67893, // Unique value for this request
    flags: 128, // Request message flag
    avpList: [
      AVP(263, 64, 0,
          ascii.encode("user12345")), // Session-Id (unique to the session)
      AVP(264, 96, 0, ascii.encode("server.com")), // Origin-Host
      AVP(296, 64, 0, ascii.encode("realm.com")), // Origin-Realm
      AVP(258, 64, 0, Uint8List.fromList([0, 0, 0, 4])), // Auth-Application-Id
      AVP(416, 96, 0,
          Uint8List.fromList([0, 0, 0, 1])), // CC-Request-Type (Authentication)
      AVP(415, 96, 0, Uint8List.fromList([0, 0, 0, 1])), // CC-Request-Number
      AVP(306, 96, 0, ascii.encode("user@example.com")), // User-Name
      AVP(
          301,
          96,
          0,
          Uint8List.fromList(
              [0, 0, 0, 0])), // User-Password (in this case just a placeholder)
    ],
  );

  // Authorization Request (AAR)
  final aarRequest = DiameterMessage.fromFields(
    version: 1,
    commandCode: 275, // Command Code for AAR
    applicationId: 4, // Diameter Credit Control Application
    hopByHopId: 12349, // Unique value for this request
    endToEndId: 67894, // Unique value for this request
    flags: 128, // Request message flag
    avpList: [
      AVP(
          263,
          64,
          0,
          ascii.encode(
              "user12345")), // Session-Id (should be the same as the one used in AIR)
      AVP(264, 96, 0, ascii.encode("server.com")), // Origin-Host
      AVP(296, 64, 0, ascii.encode("realm.com")), // Origin-Realm
      AVP(258, 64, 0, Uint8List.fromList([0, 0, 0, 4])), // Auth-Application-Id
      AVP(416, 96, 0,
          Uint8List.fromList([0, 0, 0, 2])), // CC-Request-Type (Authorization)
      AVP(
          415,
          96,
          0,
          Uint8List.fromList(
              [0, 0, 0, 2])), // CC-Request-Number (should be unique)
      AVP(301, 96, 0, ascii.encode("user@example.com")), // User-Name
      AVP(
          230,
          96,
          0,
          Uint8List.fromList(
              [0, 0, 0, 1])), // Service-Context-Id (example service context)
      AVP(416, 96, 0,
          Uint8List.fromList([0, 0, 0, 3])), // CC-Request-Type (Authorization)
      AVP(
          258,
          64,
          0,
          Uint8List.fromList(
              [0, 0, 0, 1])), // Auth-Application-Id (Authorization)
    ],
  );

  // Print encoded requests
  print("Authentication Request (AIR):");
  print(airRequest.encode());

  print("Authorization Request (AAR):");
  print(aarRequest.encode());
}


// Here’s how to construct Authentication and Authorization Diameter messages using the provided DiameterMessage class and related AVPs. These messages are typical in scenarios where a user is being authenticated and authorized for access to a service.

// Example of Authentication and Authorization Messages
// Authentication Request (AIR): This is sent by a Diameter client to a Diameter server to authenticate a user.
// Authorization Request (AAR): This is sent to authorize the user's access to resources after authentication.


// Explanation
// Authentication Request (AIR) AVPs:

// 263 (Session-Id): Unique to the session for tracking the user's authentication.
// 264 (Origin-Host): The host from which the request is coming (e.g., the Diameter client).
// 296 (Origin-Realm): The realm of the server that is processing the request.
// 258 (Auth-Application-Id): Specifies the Diameter application (4 for Diameter Credit Control).
// 416 (CC-Request-Type): Specifies the request type (1 for Authentication).
// 415 (CC-Request-Number): A unique number for each request in a session.
// 306 (User-Name): The user being authenticated.
// 301 (User-Password): The user's password (used for authentication).
// Authorization Request (AAR) AVPs:

// 263 (Session-Id): This must be the same as in the AIR.
// 264 (Origin-Host): The origin of the request.
// 296 (Origin-Realm): The realm of the sender.
// 258 (Auth-Application-Id): Diameter application ID (4 for Credit Control).
// 416 (CC-Request-Type): Specifies the request type (2 for Authorization).
// 415 (CC-Request-Number): Incremented sequence number.
// 301 (User-Name): The username being authorized.
// 230 (Service-Context-Id): The service context identifier to identify the service.
// Encoding: The encodeTo() method is used to convert these objects into the appropriate byte format for sending over the network.

// You can further extend this by adding:
// AVPs for specific services (e.g., service-specific parameters like SIP-URI for VoIP services).
// Additional command handling (e.g., handling the responses such as Authentication Accept or Authorization Accept).