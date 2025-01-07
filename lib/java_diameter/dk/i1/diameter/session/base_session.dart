import 'dart:async';

import '../avp_unsinged32.dart';
import '../avp_utf8_string.dart';
import '../message.dart';
import '../protocol_constants.dart';
import '../utils.dart';
import 'session_manager.dart';

enum State {
  idle,
  pending,
  open,
  discon,
}

class BaseSession {
  final SessionManager sessionManager;
  String? sessionId;
  State state = State.idle;
  final int authAppId;
  int sessionTimeout = 0; // seconds
  bool stateMaintained = true; // from Auth-Session-State
  late final SessionAuthTimers sessionAuthTimers;
  bool authInProgress = false;
  late final int firstAuthTime;

  BaseSession(this.authAppId, this.sessionManager) {
    sessionAuthTimers = SessionAuthTimers();
  }

  SessionManager get sessionManagerInstance => sessionManager;

  String? get sessionIdValue => sessionId;

  State get currentState => state;

  int get authAppIdValue => authAppId;

  bool get isAuthInProgress => authInProgress;

  void setAuthInProgress(bool authInProgress) {
    this.authInProgress = authInProgress;
  }

  bool get isStateMaintained => stateMaintained;

  void setStateMaintained(bool stateMaintained) {
    this.stateMaintained = stateMaintained;
  }

  int get firstAuthTimeValue => firstAuthTime;

  Future<int> handleRequest(Message request) async {
    switch (request.hdr.commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_REAUTH:
        return handleRAR(request);
      case ProtocolConstants.DIAMETER_COMMAND_ABORT_SESSION:
        return handleASR(request);
      default:
        return ProtocolConstants.DIAMETER_RESULT_COMMAND_UNSUPPORTED;
    }
  }

  Future<void> handleAnswer(Message answer, Object state) async {
    switch (answer.hdr.commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_SESSION_TERMINATION:
        handleSTA(answer);
        break;
      default:
        sessionManager.logger.warning(
            "Session '$sessionId' could not handle answer (command_code=${answer.hdr.commandCode})");
        break;
    }
  }

  Future<void> handleNonAnswer(int commandCode, Object state) async {
    switch (commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_SESSION_TERMINATION:
        handleSTA(null);
        break;
      default:
        sessionManager.logger.warning(
            "Session '$sessionId' could not handle non-answer (command_code=$commandCode)");
        break;
    }
  }

  int handleRAR(Message msg) {
    if (!authInProgress) startReauth();
    return ProtocolConstants.DIAMETER_RESULT_SUCCESS;
  }

  int handleASR(Message msg) {
    if (stateMaintained) {
      closeSession(ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_ADMINISTRATIVE);
    } else {
      state = State.idle;
      sessionManager.unregister(this);
    }
    return ProtocolConstants.DIAMETER_RESULT_SUCCESS;
  }

  void authSuccessful(Message msg) {
    if (state == State.pending) firstAuthTime = DateTime.now().millisecondsSinceEpoch;
    state = State.open;
    sessionManager.updateTimeouts(this);
  }

  void authFailed(Message msg) {
    authInProgress = false;
    sessionManager.logger.info("Authentication/Authorization failed, closing session $sessionId");
    if (state == State.pending) {
      closeSession(msg, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_ADMINISTRATIVE);
    } else {
      closeSession(msg, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_AUTH_EXPIRED);
    }
  }

  void handleSTA(Message? msg) {
    state = State.idle;
    sessionManager.unregister(this);
  }

  int calcNextTimeout() {
    int timeout = 9223372036854775807; // Long.MAX_VALUE equivalent in Dart
    if (state == State.open) {
      if (sessionTimeout != 0)
        timeout = (timeout < (firstAuthTime + sessionTimeout * 1000)) ? timeout : (firstAuthTime + sessionTimeout * 1000);
      if (!authInProgress)
        timeout = (timeout < sessionAuthTimers.getNextReauthTime()) ? timeout : sessionAuthTimers.getNextReauthTime();
      else
        timeout = (timeout < sessionAuthTimers.getMaxTimeout()) ? timeout : sessionAuthTimers.getMaxTimeout();
    }
    return timeout;
  }

  void handleTimeout() {
    if (state == State.open) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (sessionTimeout != 0 && now >= (firstAuthTime + sessionTimeout * 1000)) {
        sessionManager.logger.fine("Session-Timeout has expired, closing session");
        closeSession(null, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_SESSION_TIMEOUT);
        return;
      }
      if (now >= sessionAuthTimers.getMaxTimeout()) {
        sessionManager.logger.fine("Authorization-lifetime has expired, closing session");
        closeSession(null, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_AUTH_EXPIRED);
        return;
      }
      if (now >= sessionAuthTimers.getNextReauthTime()) {
        sessionManager.logger.fine("Authorization-lifetime(+grace-period) has expired, sending re-authorization");
        startReauth();
        sessionManager.updateTimeouts(this);
      }
    }
  }

  void newStatePre(State prevState, State newState, Message? msg, int cause) {
    // override in subclass
  }

  void newStatePost(State prevState, State newState, Message? msg, int cause) {
    // override in subclass
  }

  Future<void> openSession() async {
    if (state != State.idle) throw InvalidStateException("Session cannot be opened unless it is idle");
    if (sessionId != null) throw InvalidStateException("Sessions cannot be reused");
    sessionId = makeNewSessionId();
    state = State.pending;
    sessionManager.register(this);
    startAuth();
  }

  void closeSession(int terminationCause) {
    closeSession(null, terminationCause);
  }

  Future<void> closeSession(Message? msg, int terminationCause) async {
    switch (state) {
      case State.idle:
        return;
      case State.pending:
        newStatePre(State.pending, State.discon, msg, terminationCause);
        sendSTR(terminationCause);
        state = State.discon;
        newStatePost(State.pending, state, msg, terminationCause);
        break;
      case State.open:
        if (stateMaintained) {
          newStatePre(State.open, State.discon, msg, terminationCause);
          sendSTR(terminationCause);
          state = State.discon;
          newStatePost(State.open, state, msg, terminationCause);
        } else {
          newStatePre(State.open, State.idle, msg, terminationCause);
          state = State.idle;
          sessionManager.unregister(this);
          newStatePost(State.open, state, msg, terminationCause);
        }
        break;
      case State.discon:
        return;
    }
  }

  void startAuth() {
    // abstract method
  }

  void startReauth() {
    // abstract method
  }

  void updateSessionTimeout(int sessionTimeout) {
    this.sessionTimeout = sessionTimeout;
    sessionManager.updateTimeouts(this);
  }

  Future<void> sendSTR(int terminationCause) async {
    sessionManager.logger.fine("Sending STR for session $sessionId");
    final str = Message();
    str.hdr.setRequest(true);
    str.hdr.setProxiable(true);
    str.hdr.applicationId = authAppId;
    str.hdr.commandCode = ProtocolConstants.DIAMETER_COMMAND_SESSION_TERMINATION;
    collectSTRInfo(str, terminationCause);
    Utils.setMandatoryRFC3588(str);
    try {
      sessionManager.sendRequest(str, this, null);
    } catch (e) {
      // handle exceptions
    }
  }

  void collectSTRInfo(Message request, int terminationCause) {
    addCommonStuff(request);
    request.add(AVP_Unsigned32(ProtocolConstants.DI_AUTH_APPLICATION_ID, authAppId));
    request.add(AVP_Unsigned32(ProtocolConstants.DI_TERMINATION_CAUSE, terminationCause));
  }

  String getDestinationRealm() {
    return sessionManager.settings.realm();
  }

  String? getSessionIdOptionalPart() {
    return null;
  }

  String makeNewSessionId() {
    return sessionManager.node.makeNewSessionId(getSessionIdOptionalPart());
  }

  static int getResultCode(Message msg) {
    final avp = msg.find(ProtocolConstants.DI_RESULT_CODE);
    if (avp != null) {
      try {
        return AVP_Unsigned32(avp).queryValue();
      } catch (e) {
        return -1;
      }
    }
    return -1;
  }

  void addCommonStuff(Message request) {
    request.add(AVP_UTF8String(ProtocolConstants.DI_SESSION_ID, sessionId!));
    request.add(AVP_UTF8String(ProtocolConstants.DI_ORIGIN_HOST, sessionManager.settings.hostId()));
    request.add(AVP_UTF8String(ProtocolConstants.DI_ORIGIN_REALM, sessionManager.settings.realm()));
    request.add(AVP_UTF8String(ProtocolConstants.DI_DESTINATION_REALM, getDestinationRealm()));
  }
}
