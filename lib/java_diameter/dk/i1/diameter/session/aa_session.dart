import 'dart:async';
import 'dart:io';

import '../avp_unsinged32.dart';
import '../message.dart';
import '../protocol_constants.dart';
import 'base_session.dart';
import 'session_manager.dart';

class AASession extends BaseSession {
  static final logger = Logger('dk.i1.diameter.session.AASession');
  
  AASession(int authAppId, SessionManager sessionManager) : super(authAppId, sessionManager);

  @override
  void handleAnswer(Message answer, dynamic state) {
    switch (answer.hdr.commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_AA:
        handleAAA(answer);
        break;
      default:
        super.handleAnswer(answer, state);
        break;
    }
  }

  @override
  void handleNonAnswer(int commandCode, dynamic state) {
    switch (commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_AA:
        if (authInProgress()) {
          authFailed(null);
        } else {
          logger.info("Got a non-answer AA for session '$sessionId' when no reauth was in progress.");
        }
        break;
      default:
        super.handleNonAnswer(commandCode, state);
        break;
    }
  }

  void handleAAA(Message msg) {
    logger.finest('Handling AAA');
    if (!authInProgress()) return;
    authInProgress(false);
    if (state() == State.discon) return;
    int resultCode = getResultCode(msg);
    switch (resultCode) {
      case ProtocolConstants.DIAMETER_RESULT_SUCCESS:
        if (processAAAInfo(msg)) {
          authSuccessful(msg);
        } else {
          closeSession(msg, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_BAD_ANSWER);
        }
        break;
      case ProtocolConstants.DIAMETER_RESULT_MULTI_ROUND_AUTH:
        sendAAR();
        break;
      case ProtocolConstants.DIAMETER_RESULT_AUTHORIZATION_REJECTED:
        logger.info("Authorization for session $sessionId rejected, closing session");
        if (state() == State.pending) {
          closeSession(msg, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_BAD_ANSWER);
        } else {
          closeSession(msg, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_AUTH_EXPIRED);
        }
        break;
      default:
        logger.info("AAR failed, result_code=$resultCode");
        closeSession(msg, ProtocolConstants.DI_TERMINATION_CAUSE_DIAMETER_BAD_ANSWER);
        break;
    }
  }

  @override
  void startAuth() {
    sendAAR();
  }

  @override
  void startReauth() {
    sendAAR();
  }

  void sendAAR() {
    logger.fine("Considering sending AAR for $sessionId");
    if (authInProgress()) return;
    logger.fine("Sending AAR for $sessionId");
    authInProgress(true);
    Message aar = Message();
    aar.hdr.setRequest(true);
    aar.hdr.setProxiable(true);
    aar.hdr.applicationId = authAppId();
    aar.hdr.commandCode = ProtocolConstants.DIAMETER_COMMAND_AA;
    collectAARInfo(aar);
    Utils.setMandatoryRFC3588(aar);
    try {
      sessionManager().sendRequest(aar, this, null);
    } on NotARequestException catch (_) {
      // never happens
    } on NotRoutableException catch (ex) {
      logger.info("Could not send AAR for session $sessionId", ex);
      authFailed(null);
    }
  }

  void collectAARInfo(Message request) {
    addCommonStuff(request);
    request.add(AVP_Unsigned32(ProtocolConstants.DI_AUTH_APPLICATION_ID, authAppId()));
    // subclasses need to override this
  }

  bool processAAAInfo(Message answer) {
    logger.fine("Processing AAA info");
    try {
      AVP avp;
      int authLifetime = 0;
      avp = answer.find(ProtocolConstants.DI_AUTHORIZATION_LIFETIME);
      if (avp != null) authLifetime = AVP_Unsigned32(avp).queryValue() * 1000;
      int authGracePeriod = 0;
      avp = answer.find(ProtocolConstants.DI_AUTH_GRACE_PERIOD);
      if (avp != null) authGracePeriod = AVP_Unsigned32(avp).queryValue() * 1000;
      avp = answer.find(ProtocolConstants.DI_SESSION_TIMEOUT);
      if (avp != null) {
        int sessionTimeout = AVP_Unsigned32(avp).queryValue();
        updateSessionTimeout(sessionTimeout);
      }
      avp = answer.find(ProtocolConstants.DI_AUTH_SESSION_STATE);
      if (avp != null) {
        int stateMaintained = AVP_Unsigned32(avp).queryValue();
        stateMaintained(stateMaintained == 0);
      }

      int now = DateTime.now().millisecondsSinceEpoch;
      logger.finest("Session $sessionId: now=$now  auth_lifetime=$authLifetime auth_grace_period=$authGracePeriod");
      sessionAuthTimers.updateTimers(now, authLifetime, authGracePeriod);
      logger.finest("getNextReauthTime=${sessionAuthTimers.getNextReauthTime()} getMaxTimeout=${sessionAuthTimers.getMaxTimeout()}");
    } on InvalidAVPLengthException catch (_) {
      return false;
    }
    return true;
  }
}
