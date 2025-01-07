import 'dart:math';

  enum TimerAction {
    none,
    disconnectNoCer,
    disconnectIdle,
    disconnectNoDw,
    dwr
  }

class ConnectionTimers {
  int lastActivity;
  int lastRealActivity;
  int lastInDw;
  bool dwOutstanding;
  int cfgWatchdogTimer;
  int watchdogTimerWithJitter;
  int cfgIdleCloseTimeout;

  static Random? random;

  // Return -2000..+2000 as per RFC 3539 section 3.4.1 item 1
  // Generates a jitter value based on the specified logic
  static int generateJitter() {
    if (random == null) {
      random = Random.secure();
    }

    // Random.nextBytes() in Dart doesn't exist, so we simulate it
    int x = random!.nextInt(256) * 256 + random!.nextInt(256);
    if (x < 0) x += 65536;
    x %= 4001;
    x -= 2000;
    return x;
  }

  ConnectionTimers(int watchdogTimer, int idleCloseTimeout)
      : lastActivity = DateTime.now().millisecondsSinceEpoch,
        lastRealActivity = DateTime.now().millisecondsSinceEpoch,
        lastInDw = DateTime.now().millisecondsSinceEpoch,
        dwOutstanding = false,
        cfgWatchdogTimer = watchdogTimer,
        watchdogTimerWithJitter = watchdogTimer + generateJitter(),
        cfgIdleCloseTimeout = idleCloseTimeout;

  void markDWR() {
    lastInDw = DateTime.now().millisecondsSinceEpoch;
  }

  void markDWA() {
    lastInDw = DateTime.now().millisecondsSinceEpoch;
    dwOutstanding = false;
  }

  void markActivity() {
    lastActivity = DateTime.now().millisecondsSinceEpoch;
  }

  void markCER() {
    lastActivity = DateTime.now().millisecondsSinceEpoch;
  }

  void markRealActivity() {
    lastRealActivity = lastActivity;
  }

  void markDWR_out() {
    dwOutstanding = true;
    lastActivity = DateTime.now().millisecondsSinceEpoch;
    watchdogTimerWithJitter = cfgWatchdogTimer + generateJitter();
  }



  int calcNextTimeout(bool ready) {
    if (!ready) {
      // when we haven't received a CER or negotiated TLS, it will time out
      return lastActivity + watchdogTimerWithJitter;
    }

    int nextWatchdogTimeout;

    if (!dwOutstanding) {
      nextWatchdogTimeout = lastActivity + watchdogTimerWithJitter; // when to send a DWR
    } else {
      nextWatchdogTimeout = lastActivity + watchdogTimerWithJitter + cfgWatchdogTimer; // when to kill the connection due to no response
    }

    if (cfgIdleCloseTimeout != 0) {
      int idleTimeout = lastRealActivity + cfgIdleCloseTimeout;
      if (idleTimeout < nextWatchdogTimeout) return idleTimeout;
    }
    return nextWatchdogTimeout;
  }

  TimerAction calcAction(bool ready) {
    int now = DateTime.now().millisecondsSinceEpoch;

    if (!ready) {
      if (now >= lastActivity + watchdogTimerWithJitter) {
        return TimerAction.disconnectNoCer;
      }
      return TimerAction.none;
    }

    if (cfgIdleCloseTimeout != 0) {
      if (now >= lastRealActivity + cfgIdleCloseTimeout) {
        return TimerAction.disconnectIdle;
      }
    }

    // section 3.4.1 item 1
    if (now >= lastActivity + watchdogTimerWithJitter) {
      if (!dwOutstanding) {
        return TimerAction.dwr;
      } else {
        if (now >= lastActivity + cfgWatchdogTimer + cfgWatchdogTimer) {
          // section 3.4.1 item 3+4
          return TimerAction.disconnectNoDw;
        }
      }
    }
    return TimerAction.none;
  }
}
