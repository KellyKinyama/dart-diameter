/// Authorization time calculator.
/// This utility class keeps track of the authorization-lifetime and
/// authorization-grace-period and calculates when the session must be closed or
/// when a re-authorization must be sent.
class SessionAuthTimers {
  int latestAuthTime = 0; // absolute, milliseconds
  int nextReauthTime = 0; // absolute, milliseconds
  int authTimeout = 0; // absolute, milliseconds

  /// Updates the calculations based on the supplied values. The method
  /// will try to schedule the re-authorization (if any) 10 seconds before
  /// the session would have to be closed otherwise.
  ///
  /// [authTime] The time when the authorization succeeded (absolute, milliseconds).
  /// Ideally, this should be the time when the user is given service (for the first
  /// authorization), and the server's time when the re-authorization succeeds.
  /// In most cases, `DateTime.now().millisecondsSinceEpoch` will do.
  ///
  /// [authLifetime] The granted authorization lifetime in relative milliseconds.
  /// Use 0 to specify no authorization-lifetime.
  ///
  /// [authGracePeriod] The authorization-grace-period in relative milliseconds.
  /// Use 0 to specify none.
  void updateTimers(int authTime, int authLifetime, int authGracePeriod) {
    latestAuthTime = authTime;
    if (authLifetime != 0) {
      authTimeout = latestAuthTime + authLifetime + authGracePeriod;
      if (authGracePeriod != 0) {
        nextReauthTime = latestAuthTime + authLifetime;
      } else {
        // schedule reauth to 10 seconds before timeout. Should be plenty for carrier-grade servers.
        nextReauthTime =
            (authTime + authLifetime ~/ 2).clamp(0, authTimeout - 10);
      }
    } else {
      nextReauthTime = double.infinity.toInt();
      authTimeout = double.infinity.toInt();
    }
  }

  /// Retrieve the calculated time for the next re-authorization.
  ///
  /// @return The next re-authorization time, in milliseconds. Will be
  ///         `double.infinity` if there is none.
  int getNextReauthTime() {
    return nextReauthTime;
  }

  /// Retrieve the maximum timeout of the session after which service must
  /// be denied and the session should be closed.
  ///
  /// @return The timeout. Will be `double.infinity` if there is no timeout.
  int getMaxTimeout() {
    return authTimeout;
  }
}
