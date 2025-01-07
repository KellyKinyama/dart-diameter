import 'capability.dart';
import 'node_settings.dart';
import 'node_validator.dart';

class AuthenticationResult {
  bool known = false;
}

class DefaultNodeValidator implements NodeValidator {
  /**
   * "authenticates" peer.
   * Always claims to know any peer.
   */
  @override
  AuthenticationResult authenticateNode(String nodeId, Object obj) {
    AuthenticationResult ar = AuthenticationResult();
    ar.known = true;
    return ar;
  }

  /**
   * "authorizes" the capabilities claimed by a peer.
   * This implementation returns the simple intersection of the peers reported capabilities and our own capabilities.
   * Implemented as: return Capability.calculateIntersection(settings.capabilities(), reportedCapabilities);
   */
  Capability authorizeNode(String nodeId, NodeSettings settings, Capability reportedCapabilities) {
    Capability resultCapabilities = Capability.calculateIntersection(settings.capabilities(), reportedCapabilities);
    return resultCapabilities;
  }
}
