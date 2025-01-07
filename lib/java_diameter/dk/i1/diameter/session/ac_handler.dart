// import 'package:diameter/diameter.dart';
import 'dart:collection';
import 'dart:developer';

import '../avp.dart';
import '../avp_time.dart';
import '../avp_unsigned64.dart';
import '../avp_unsinged32.dart';
import '../message.dart';
import '../protocol_constants.dart';
import 'base_session.dart';

/// A collection of data belonging to a (sub-)session.
/// The user of the ACHandler class is supposed to update the acct_* fields
/// either before calling [handleTimeout], [startSubSession], [stopSubSession],
/// [stopSession], or [sendEvent], or whenever new usage information is received for the user.
class SubSession {
  final int subsessionId;
  bool startSent = false;
  late int interimInterval;
  late int nextInterim;
  int mostRecentRecordNumber = -1;

  /// The accounting session-time, in milliseconds. Can be null
  int? acctSessionTime;

  /// The number of octets received from the user. Can be null
  int? acctInputOctets;

  /// The number of octets sent to the user. Can be null
  int? acctOutputOctets;

  /// The number of packets received from the user. Can be null
  int? acctInputPackets;

  /// The number of packets sent to the user. Can be null
  int? acctOutputPackets;

  SubSession(this.subsessionId) {
    interimInterval = 9223372036854775807; // Long.MAX_VALUE
    nextInterim = 9223372036854775807; // Long.MAX_VALUE
  }
}

/// A utility class for dealing with accounting.
/// It supports sub-sessions, interim accounting, and other common stuff.
/// It can be used for incorporating into session classes. The session must dispatch ACAs to it.
class ACHandler {
  final BaseSession baseSession;
  late int subsessionSequencer;
  int accountingRecordNumber = 0;

  /// The acct-multi-session-id to include in ACRs, if any
  String? acctMultiSessionId;

  /// The acct-application-id to include in ACRs. If not set, then collectACRInfo() must be overridden to add a vendor-specific-application AVP
  int? acctApplicationId;

  final Map<int, SubSession> subsessions = {};

  /// Constructor for ACHandler
  /// @param baseSession The BaseSession (or subclass thereof) for which accounting should be produced.
  ACHandler(this.baseSession) {
    subsessionSequencer = 0;
    subsessions[subsessionSequencer] = SubSession(subsessionSequencer++);
  }

  /// Calculate the next time that handleTimeouts() should be called.
  /// The timeout is calculated based on the earliest timeout of interim for any of the subsessions
  int calcNextTimeout() {
    int t = 9223372036854775807; // Long.MAX_VALUE
    subsessions.forEach((_, ss) {
      t = ss.nextInterim < t ? ss.nextInterim : t;
    });
    return t;
  }

  /// Process timeouts, if any. Accounting-interim requests may get sent.
  void handleTimeout() {
    int now = DateTime.now().millisecondsSinceEpoch;
    subsessions.forEach((_, ss) {
      if (ss.nextInterim <= now) {
        sendInterim(ss);
      }
    });
  }

  /// Creates a sub-session with a unique sub-session-id.
  /// It is the responsibility of the caller to call startSubSession() afterward.
  /// The Sub-session is not automatically started.
  int createSubSession() {
    SubSession ss = SubSession(subsessionSequencer++);
    subsessions[ss.subsessionId] = ss;
    return ss.subsessionId;
  }

  /// Retrieve a sub-session by id
  /// @param subsessionId The sub-session id
  /// @return The sub-session, or null if not found.
  SubSession? subSession(int subsessionId) {
    return subsessions[subsessionId];
  }

  /// Start sub-session accounting for the specified sub-session.
  /// This will result in the ACR start-record being sent.
  void startSubSession(int subsessionId) {
    if (subsessionId == 0) return;
    SubSession? ss = subSession(subsessionId);
    if (ss == null || ss.startSent) return; // already started
    sendStart(ss);
  }

  /// Stop a sub-session.
  /// The sub-session is stopped (accounting-stop ACR will be generated)
  /// and the sub-session will be removed.
  void stopSubSession(int subsessionId) {
    if (subsessionId == 0) return;
    SubSession? ss = subSession(subsessionId);
    if (ss == null) return;
    sendStop(ss);
    subsessions.remove(ss.subsessionId);
  }

  /// Start accounting for the session.
  /// This will result in the ACR start-record being sent.
  void startSession() {
    SubSession? ss = subSession(0);
    if (ss == null || ss.startSent) return;
    sendStart(ss);
  }

  /// Stop accounting.
  /// Stop accounting by sending ACRs (stop records) for all sub-sessions
  /// and deleting them, and then finally sending an ACR stop-record for the whole session.
  void stopSession() {
    subsessions.forEach((_, ss) {
      if (ss.subsessionId != 0) sendStop(ss);
    });
    SubSession? ss = subSession(0);
    if (ss != null) sendStop(ss);
    subsessions.clear();
  }

  /// Send an event record for the whole session.
  void sendEvent() {
    sendEvent(0, null);
  }

  /// Send an event record for the sub-session with an additional set of AVPs
  void sendEvent(int subsessionId, List<AVP>? avps) {
    SubSession? ss = subSession(subsessionId);
    if (ss == null) return;
    sendEvent(ss, avps);
  }

  /// Send an event record for the sub-session with an additional set of AVPs.
  /// collectACR() will be called and the AVPs will then be added to the ACR, and then sent.
  void sendEvent(SubSession ss, List<AVP>? avps) {
    Message acr =
        makeACR(ss, ProtocolConstants.DI_ACCOUNTING_RECORD_TYPE_EVENT_RECORD);
    if (avps != null) {
      for (AVP a in avps) acr.add(a);
    }
    sendACR(acr);
  }

  // Private methods
  void sendStart(SubSession ss) {
    sendACR(
        makeACR(ss, ProtocolConstants.DI_ACCOUNTING_RECORD_TYPE_START_RECORD));
    if (ss.interimInterval != 9223372036854775807)
      ss.nextInterim =
          DateTime.now().millisecondsSinceEpoch + ss.interimInterval;
    else
      ss.nextInterim = 9223372036854775807;
  }

  void sendInterim(SubSession ss) {
    sendACR(makeACR(
        ss, ProtocolConstants.DI_ACCOUNTING_RECORD_TYPE_INTERIM_RECORD));
    if (ss.interimInterval != 9223372036854775807)
      ss.nextInterim =
          DateTime.now().millisecondsSinceEpoch + ss.interimInterval;
    else
      ss.nextInterim = 9223372036854775807;
  }

  void sendStop(SubSession ss) {
    sendACR(
        makeACR(ss, ProtocolConstants.DI_ACCOUNTING_RECORD_TYPE_STOP_RECORD));
  }

  void sendACR(Message acr) {
    try {
      baseSession.sessionManager().sendRequest(acr, baseSession, null);
    } catch (e) {
      logger.severe('Error sending ACR: $e');
    }
  }

  Message makeACR(SubSession ss, int recordType) {
    Message acr = Message();
    acr.hdr.setRequest(true);
    acr.hdr.setProxiable(true);
    acr.hdr.applicationId = baseSession.authAppId();
    acr.hdr.commandCode = ProtocolConstants.DIAMETER_COMMAND_ACCOUNTING;
    collectACRInfo(acr, ss, recordType);
    Utils.setMandatory_RFC3588(acr);
    return acr;
  }

  void collectACRInfo(Message acr, SubSession ss, int recordType) {
    baseSession.addCommonStuff(acr);
    acr.add(AVP_Unsigned32(
        ProtocolConstants.DI_ACCOUNTING_RECORD_TYPE, recordType));

    accountingRecordNumber++;
    acr.add(AVP_Unsigned32(
        ProtocolConstants.DI_ACCOUNTING_RECORD_NUMBER, accountingRecordNumber));
    ss.mostRecentRecordNumber = accountingRecordNumber;

    if (acctApplicationId != null)
      acr.add(AVP_Unsigned32(
          ProtocolConstants.DI_ACCT_APPLICATION_ID, acctApplicationId));

    if (ss.subsessionId != 0)
      acr.add(AVP_Unsigned64(
          ProtocolConstants.DI_ACCOUNTING_SUB_SESSION_ID, ss.subsessionId));

    if (acctMultiSessionId != null)
      acr.add(AVP_UTF8String(
          ProtocolConstants.DI_ACCT_MULTI_SESSION_ID, acctMultiSessionId));

    if (ss.interimInterval != 9223372036854775807)
      acr.add(AVP_Unsigned32(ProtocolConstants.DI_ACCT_INTERIM_INTERVAL,
          (ss.interimInterval ~/ 1000).toInt()));

    acr.add(AVP_Time(ProtocolConstants.DI_EVENT_TIMESTAMP,
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toInt()));

    if (recordType !=
        ProtocolConstants.DI_ACCOUNTING_RECORD_TYPE_START_RECORD) {
      if (ss.acctSessionTime != null)
        acr.add(AVP_Unsigned32(ProtocolConstants.DI_ACCT_SESSION_TIME,
            (ss.acctSessionTime! ~/ 1000).toInt()));
      if (ss.acctInputOctets != null)
        acr.add(AVP_Unsigned64(
            ProtocolConstants.DI_ACCOUNTING_INPUT_OCTETS, ss.acctInputOctets!));
      if (ss.acctOutputOctets != null)
        acr.add(AVP_Unsigned64(ProtocolConstants.DI_ACCOUNTING_OUTPUT_OCTETS,
            ss.acctOutputOctets!));
      if (ss.acctInputPackets != null)
        acr.add(AVP_Unsigned64(ProtocolConstants.DI_ACCOUNTING_INPUT_PACKETS,
            ss.acctInputPackets!));
      if (ss.acctOutputPackets != null)
        acr.add(AVP_Unsigned64(ProtocolConstants.DI_ACCOUNTING_OUTPUT_PACKETS,
            ss.acctOutputPackets!));
    }
  }
}
