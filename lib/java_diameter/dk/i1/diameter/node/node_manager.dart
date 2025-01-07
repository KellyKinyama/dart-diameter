import 'dart:async';
import 'dart:io';

import 'connection_key.dart';
import 'connection_listener.dart';
import 'message_dispatcher.dart';

 class RequestData {
    var state;
    int timeoutTime;
    RequestData(this.state, this.timeoutTime);
  }

class NodeManager implements MessageDispatcher, ConnectionListener {
  // Equivalent of RequestData class in Dart
 

  late Node node;
  late NodeSettings settings;
  late Map<ConnectionKey, Map<int, RequestData>> reqMap;
  //late Logger logger;
  bool stopTimeoutThread = false;
  late TimeoutThread timeoutThread;
  bool timeoutThreadActivelyWaiting = false;

  // Constructor for NodeManager
  NodeManager(NodeSettings settings) : this(settings, null);

  NodeManager(NodeSettings settings, NodeValidator? nodeValidator) {
    node = Node(this, this, settings, nodeValidator);
    this.settings = settings;
    reqMap = {};
    //logger = Logger('dk.i1.diameter.node');
  }

  // Start the NodeManager
  Future<void> start() async {
    await node.start();
    stopTimeoutThread = false;
    timeoutThreadActivelyWaiting = false;
    timeoutThread = TimeoutThread();
    timeoutThread.setDaemon(true);
    timeoutThread.start();
  }

  // Stop the NodeManager
  void stop([int graceTime = 0]) {
    node.stop(graceTime);
    stopTimeoutThread = true;
    reqMap.forEach((connKey, requests) {
      requests.forEach((_, requestData) {
        handleAnswer(null, connKey, requestData.state);
      });
    });
    timeoutThread.join();
    reqMap.clear();
  }

  // Wait for a connection
  Future<void> waitForConnection() async {
    await node.waitForConnection();
  }

  // Wait with timeout
  Future<void> waitForConnectionWithTimeout(int timeout) async {
    await node.waitForConnection(timeout);
  }

  // Get the Node instance
  Node get nodeInstance => node;

  // Get the settings
  NodeSettings get settingsInstance => settings;

  // Handle incoming requests
  @override
  void handleRequest(Message request, ConnectionKey connkey, Peer peer) {
    var answer = Message();
    logger.finer('Handling incoming request, command_code=${request.hdr.commandCode}, peer=${peer.host()}, end2end=${request.hdr.endToEndIdentifier}, hopbyhop=${request.hdr.hopByHopIdentifier}');
    answer.prepareResponse(request);
    answer.hdr.setError(true);
    answer.add(AVP_Unsigned32(ProtocolConstants.DI_RESULT_CODE, ProtocolConstants.DIAMETER_RESULT_UNABLE_TO_DELIVER));
    node.addOurHostAndRealm(answer);
    Utils.copyProxyInfo(request, answer);
    Utils.setMandatory_RFC3588(answer);
    try {
      answer(answer, connkey);
    } catch (NotAnAnswerException) {}
  }

  // Handle incoming answer
  @override
  void handleAnswer(Message answer, ConnectionKey answerConnKey, var state) {
    logger.finer('Handling incoming answer, command_code=${answer.hdr.commandCode}, end2end=${answer.hdr.endToEndIdentifier}, hopbyhop=${answer.hdr.hopByHopIdentifier}');
  }

  // Send an answer
  void answer(Message answer, ConnectionKey connkey) {
    if (answer.hdr.isRequest()) throw NotAnAnswerException();
    try {
      node.sendMessage(answer, connkey);
    } catch (StaleConnectionException) {}
  }

  // Forward request
  void forwardRequest(Message request, ConnectionKey connkey, var state) {
    forwardRequest(request, connkey, state, -1);
  }

  void forwardRequest(Message request, ConnectionKey connkey, var state, int timeout) {
    if (!request.hdr.isProxiable()) throw NotProxiableException();
    var ourHostId = settings.hostId();
    bool ourRouteRecordFound = false;
    for (AVP a in request.subset(ProtocolConstants.DI_ROUTE_RECORD)) {
      if (AVP_UTF8String(a).queryValue() == ourHostId) {
        ourRouteRecordFound = true;
        break;
      }
    }
    if (!ourRouteRecordFound) {
      request.add(AVP_UTF8String(ProtocolConstants.DI_ROUTE_RECORD, settings.hostId()));
    }
    sendRequest(request, connkey, state, timeout);
  }

  // Sends a request
  Future<void> sendRequest(Message request, ConnectionKey connkey, var state, [int timeout = -1]) async {
    if (!request.hdr.isRequest()) throw NotARequestException();
    request.hdr.hopByHopIdentifier = node.nextHopByHopIdentifier(connkey);
    reqMap[connkey]?[request.hdr.hopByHopIdentifier] = RequestData(state, DateTime.now().millisecondsSinceEpoch + timeout);
    if (timeout >= 0 && !timeoutThreadActivelyWaiting) {
      reqMap.notify();
    }
    await node.sendMessage(request, connkey);
    logger.finer('Request sent, command_code=${request.hdr.commandCode} hop_by_hop_identifier=${request.hdr.hopByHopIdentifier}');
  }

  // Handle incoming messages
  @override
  bool handle(Message msg, ConnectionKey connkey, Peer peer) {
    if (msg.hdr.isRequest()) {
      logger.finer('Handling request');
      handleRequest(msg, connkey, peer);
    } else {
      logger.finer('Handling answer, hop_by_hop_identifier=${msg.hdr.hopByHopIdentifier}');
      var state;
      bool found = false;
      synchronized(reqMap, () {
        var eC = reqMap[connkey];
        if (eC != null) {
          var rd = eC[msg.hdr.hopByHopIdentifier];
          if (rd != null) {
            state = rd.state;
            eC.remove(msg.hdr.hopByHopIdentifier);
            found = true;
          }
        }
      });
      if (found) {
        handleAnswer(msg, connkey, state);
      } else {
        logger.info('Answer did not match any outstanding request');
      }
    }
    return true;
  }

  // Handle connection state changes
  @override
  void handle(ConnectionKey connkey, Peer peer, bool up) {
    synchronized(reqMap, () {
      if (up) {
        reqMap[connkey] = {};
      } else {
        var eC = reqMap[connkey];
        if (eC != null) {
          reqMap.remove(connkey);
          eC.forEach((_, requestData) {
            handleAnswer(null, connkey, requestData.state);
          });
        }
      }
    });
  }

  // TimeoutThread for handling request timeouts
  class TimeoutThread extends Thread {
    TimeoutThread() : super('NodeManager request timeout thread');

    @override
    void run() {
      while (!stopTimeoutThread) {
        synchronized(reqMap, () {
          bool anyTimeoutsFound = false;
          var now = DateTime.now().millisecondsSinceEpoch;
          reqMap.forEach((connKey, requests) {
            requests.forEach((_, requestData) {
              if (requestData.timeoutTime >= 0) anyTimeoutsFound = true;
              if (requestData.timeoutTime >= 0 && requestData.timeoutTime <= now) {
                requests.remove(requestData);
                logger.finest('Timing out request');
                handleAnswer(null, connKey, requestData.state);
              }
            });
          });
          if (anyTimeoutsFound) {
            timeoutThreadActivelyWaiting = true;
            reqMap.wait(1000);
          } else {
            reqMap.wait();
          }
          timeoutThreadActivelyWaiting = false;
        });
      }
    }
  }
}

