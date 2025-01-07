
import '../dk/i1/diameter/avp_unsinged32.dart';
import '../dk/i1/diameter/avp_utf8_string.dart';
import '../dk/i1/diameter/message.dart';
import '../dk/i1/diameter/protocol_constants.dart';
import '../dk/i1/diameter/session/aa_session.dart';
import '../dk/i1/diameter/session/ac_handler.dart';
import '../dk/i1/diameter/session/base_session.dart';
import '../dk/i1/diameter/session/session.dart';
import 'dart:async';
import 'dart:developer';

import '../dk/i1/diameter/session/session_manager.dart';

/// A simple session based on AASession, supporting simple accounting.
/// This class is used by some of the other examples.
class TestSession extends AASession {
  static final logger = Logger('TestSession');
  late ACHandler achandler;

  TestSession(int authAppId, SessionManager sessionManager) : super(authAppId, sessionManager) {
    achandler = ACHandler(this);
    achandler.acctApplicationId = ProtocolConstants.DIAMETER_APPLICATION_NASREQ;
  }

  @override
  void handleAnswer(Message answer, dynamic state) {
    logger.fine('Processing answer');
    switch (answer.hdr.commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_ACCOUNTING:
        achandler.handleACA(answer);
        break;
      default:
        super.handleAnswer(answer, state);
        break;
    }
  }

  @override
  void handleNonAnswer(int commandCode, dynamic state) {
    logger.fine('Processing non-answer');
    switch (commandCode) {
      case ProtocolConstants.DIAMETER_COMMAND_ACCOUNTING:
        achandler.handleACA(null);
        break;
      default:
        super.handleNonAnswer(commandCode, state);
        break;
    }
  }

  @override
  void collectAARInfo(Message request) {
    super.collectAARInfo(request);
    request.add(AVP_UTF8String(ProtocolConstants.DI_USER_NAME, "user@example.net"));
  }

  @override
  bool processAAAInfo(Message answer) {
    try {
      var it = answer.iterator(ProtocolConstants.DI_ACCT_INTERIM_INTERVAL);
      if (it.isNotEmpty) {
        int interimInterval = AVP_Unsigned32(it.first).queryValue();
        if (interimInterval != 0) {
          achandler.subSession(0).interimInterval = interimInterval * 1000;
        }
      }
    } catch (e) {
      return false;
    }
    return super.processAAAInfo(answer);
  }

  @override
  int calcNextTimeout() {
    int t = super.calcNextTimeout();
    if (state() == State.open) {
      t = t < achandler.calcNextTimeout() ? t : achandler.calcNextTimeout();
    }
    return t;
  }

  @override
  void handleTimeout() {
    // Update acct_session_time
    if (state() == State.open) {
      achandler.subSession(0).acctSessionTime = DateTime.now().millisecondsSinceEpoch - firstAuthTime();
    }
    // Then do the timeout handling
    super.handleTimeout();
    achandler.handleTimeout();
  }

  @override
  void newStatePre(State prevState, State newState, Message msg, int cause) {
    logger.fine('prev=$prevState new=$newState');
    if (prevState != State.discon && newState == State.discon) {
      achandler.stopSession();
    }
  }

  @override
  void newStatePost(State prevState, State newState, Message msg, int cause) {
    logger.fine('prev=$prevState new=$newState');
    if (prevState != State.open && newState == State.open) {
      achandler.startSession();
    }
  }
}
