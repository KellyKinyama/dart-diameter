import 'dart:async';
import 'dart:collection';

import '../avp.dart';
import '../avp_unsinged32.dart';
import '../avp_utf8_string.dart';
import '../message.dart';
import '../node/node_manager.dart';
import '../node/node_settings.dart';
import '../node/peer.dart';
import '../protocol_constants.dart';
import '../utils.dart';
import 'session.dart';

class SessionAndTimeout {
  Session session;
  int timeout;
  bool deleted;

  SessionAndTimeout(this.session) {
    this.timeout = session.calcNextTimeout();
    this.deleted = false;
  }
}

class SessionManager extends NodeManager {
  Map<String, SessionAndTimeout> mapSession = {};
  List<Peer> peers;
  late Timer timer;
  int earliestTimeout = 9223372036854775807;
  bool stop = false;
  Logger logger;

  SessionManager(NodeSettings settings, this.peers) : super(settings) {
    if (settings.port == 0) {
      throw InvalidSettingException(
          "If you have sessions then you must allow inbound connections");
    }
    logger = Logger('dk.i1.diameter.session');
  }

  Future<void> start() async {
    logger.fine('Starting session manager');
    await super.start();
    timer = Timer.periodic(Duration(milliseconds: 100), _timerTick);
    for (var peer in peers) {
      await node.initiateConnection(peer, true);
    }
  }

  void stop(int graceTime) {
    logger.fine('Stopping session manager');
    super.stop(graceTime);
    synchronized(mapSession, () {
      stop = true;
      mapSession.notify();
    });
    timer.cancel();
    logger.fine('Session manager stopped');
  }

  void handleRequest(Message request, ConnectionKey connKey, Peer peer) {
    logger.fine('Handling request, command_code=${request.hdr.commandCode}');
    // todo: verify that destination-host is us
    Message answer = Message();
    answer.prepareResponse(request);

    String? sessionId = extractSessionId(request);
    if (sessionId == null) {
      logger.fine('Cannot handle request - no Session-Id AVP in request');
      answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE,
          ProtocolConstants.DIAMETER_RESULT_MISSING_AVP));
      node().addOurHostAndRealm(answer);
      answer.add(AVP_Grouped(ProtocolConstants.DI_FAILED_AVP,
          [AVP_UTF8String(ProtocolConstants.DI_SESSION_ID, '')]));
      Utils.copyProxyInfo(request, answer);
      Utils.setMandatory_RFC3588(answer);
      try {
        answer(answer, connKey);
      } catch (e) {}
      return;
    }
    Session s = findSession(sessionId);
    if (s == null) {
      logger.fine(
          "Cannot handle request - Session-Id '$sessionId' does not denote a known session");
      answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE,
          ProtocolConstants.DIAMETER_RESULT_UNKNOWN_SESSION_ID));
      node().addOurHostAndRealm(answer);
      Utils.copyProxyInfo(request, answer);
      Utils.setMandatory_RFC3588(answer);
      try {
        answer(answer, connKey);
      } catch (e) {}
      return;
    }
    int resultCode = s.handleRequest(request);
    answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE, resultCode));
    node().addOurHostAndRealm(answer);
    Utils.copyProxyInfo(request, answer);
    Utils.setMandatory_RFC3588(answer);
    try {
      answer(answer, connKey);
    } catch (e) {}
  }

  void handleAnswer(Message answer, ConnectionKey answerConnKey, Object state) {
    if (answer != null) {
      logger.fine('Handling answer, command_code=${answer.hdr.commandCode}');
    } else {
      logger.fine('Handling non-answer');
    }
    Session s;
    String? sessionId = extractSessionId(answer);
    logger.finest('session-id=$sessionId');
    if (sessionId != null) {
      s = findSession(sessionId);
    } else {
      s = (state as RequestState).session;
    }
    if (s == null) {
      logger.fine('Session "$sessionId" not found');
      return;
    }
    logger.fine('Found session, dispatching (non-)answer to it');

    if (answer != null) {
      s.handleAnswer(answer, (state as RequestState).state);
    } else {
      s.handleNonAnswer(
          (state as RequestState).commandCode, (state as RequestState).state);
    }
  }

  Future<void> sendRequest(
      Message request, Session session, Object state) async {
    logger.fine(
        'Sending request (command_code=${request.hdr.commandCode}) for session ${session.sessionId()}');
    RequestState rs = RequestState()
      ..commandCode = request.hdr.commandCode
      ..state = state
      ..session = session;
    await sendRequest(request, peers(request), rs);
  }

  List<Peer> peers() {
    return peers;
  }

  List<Peer> peers(Message request) {
    return peers;
  }

  void register(Session s) {
    SessionAndTimeout sat = SessionAndTimeout(s);
    synchronized(mapSession, () {
      mapSession[s.sessionId()] = sat;
      if (sat.timeout < earliestTimeout) mapSession.notify();
    });
  }

  void unregister(Session s) {
    logger.fine('Unregistering session ${s.sessionId()}');
    synchronized(mapSession, () {
      SessionAndTimeout? sat = mapSession[s.sessionId()];
      if (sat != null) {
        sat.deleted = true;
        if (earliestTimeout == 9223372036854775807) mapSession.notify();
        return;
      }
    });
    logger.warning('Could not find session ${s.sessionId()}');
  }

  void updateTimeouts(Session s) {
    synchronized(mapSession, () {
      SessionAndTimeout? sat = mapSession[s.sessionId()];
      if (sat == null) return;
      sat.timeout = s.calcNextTimeout();
      if (sat.timeout < earliestTimeout) mapSession.notify();
    });
  }

  Session? findSession(String sessionId) {
    synchronized(mapSession, () {
      SessionAndTimeout? sat = mapSession[sessionId];
      return sat != null && !sat.deleted ? sat.session : null;
    });
  }

  String? extractSessionId(Message msg) {
    if (msg == null) return null;
    Iterator<AVP> it = msg.iterator(ProtocolConstants.DI_SESSION_ID);
    if (!it.hasNext()) return null;
    return AVP_UTF8String(it.next()).queryValue();
  }

  void _timerTick(Timer timer) {
    synchronized(mapSession, () {
      while (!stop) {
        int now = DateTime.now().millisecondsSinceEpoch;
        earliestTimeout = 9223372036854775807;
        for (var entry in mapSession.entries) {
          if (entry.value.deleted) {
            mapSession.remove(entry.key);
            continue;
          }
          Session session = entry.value.session;
          if (entry.value.timeout < now) {
            session.handleTimeout();
            entry.value.timeout = session.calcNextTimeout();
          }
          earliestTimeout = earliestTimeout < entry.value.timeout
              ? earliestTimeout
              : entry.value.timeout;
        }
        now = DateTime.now().millisecondsSinceEpoch;
        if (earliestTimeout > now) {
          if (earliestTimeout == 9223372036854775807) {
            mapSession.wait();
          } else {
            mapSession.wait(earliestTimeout - now);
          }
        }
      }
    });
  }
}

class RequestState {
  int commandCode = 0;
  Object? state;
  Session? session;
}

class Logger {
  Logger(String name);
  void fine(String message) {}
  void finest(String message) {}
  void warning(String message) {}
}

class InvalidSettingException implements Exception {
  InvalidSettingException(String message);
}

class NotRoutableException implements Exception {}

class NotARequestException implements Exception {}

class ConnectionKey {}

void synchronized(
    Map<String, SessionAndTimeout> mapSession, void Function() action) {
  action();
}
