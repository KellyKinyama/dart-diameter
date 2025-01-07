import '../message.dart'; // Assuming Message class is already defined in this path

/// The session interface is what the [SessionManager] operates on.
/// See: BaseSession
abstract class Session {
  /// sessionId() is called by the SessionManager (and other classes) to
  /// obtain the Diameter Session-Id of the session. The BaseSession
  /// class implements this by following RFC3588 section 8.8
  /// @return The stable, eternally unique session-id of the session
  String sessionId();

  /// This method is called when the SessionManager has received a request
  /// for this session.
  /// @param request The Diameter request for this session.
  /// @return the Diameter result-code (RFC3588 section 7.1)
  int handleRequest(Message request);

  /// This method is called when the SessionManager has received an answer
  /// regarding this session.
  /// @param answer The Diameter answer for this session.
  /// @param state The state specified in the [SessionManager.sendRequest] call.
  void handleAnswer(Message answer, dynamic state);

  /// This method is called when the SessionManager did not receive an
  /// answer.
  /// @param commandCode The command_code in the original request.
  /// @param state The state specified in the [SessionManager.sendRequest] call.
  void handleNonAnswer(int commandCode, dynamic state);

  /// Calculate the next timeout for this session, if any. This method is
  /// called by the SessionManager at appropriate times in order to
  /// calculate when handleTimeouts() should be called.
  /// @return Next absolute timeout in milliseconds. `double.infinity` if none.
  int calcNextTimeout();

  /// Handle timeouts, if any.
  /// This method is called by the SessionManager when it thinks that a
  /// timeout has expired for the session. The session can take any
  /// action it deems appropriate. The method may be called when no
  /// timeouts have expired, so the implementation should not get upset
  /// about that.
  void handleTimeout();
}
