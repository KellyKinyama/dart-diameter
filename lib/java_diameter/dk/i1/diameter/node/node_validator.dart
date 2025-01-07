import 'capability.dart';

class AuthenticationResult {
  bool known = false;
  String? errorMessage;
  int? resultCode;
}

abstract class NodeValidator {
  /// Authentication result for a node.

  /// Verify that we know the node.
  /// This method is called when a peer connects and tells us its name in a CER.
  /// The implementation should return an [AuthenticationResult] telling the node if we know the peer,
  /// and if not what the result-code and error-message should be.
  AuthenticationResult authenticateNode(String hostId, Object obj);

  /// Calculate the capabilities that we allow the peer to have.
  /// This method is called after the node has been authenticated.
  /// Note: This method is also called for outbound connections.
  /// If the resulting common capability is empty, then the peer will be disconnected with Result-Code 5010 ("no common application").
  Capability authorizeNode(
      String hostId, NodeSettings settings, Capability reportedCapabilities);
}
