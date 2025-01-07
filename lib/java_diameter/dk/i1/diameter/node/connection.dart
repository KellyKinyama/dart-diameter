import 'dart:collection';
import 'dart:math';
import 'dart:io';

import 'connection_key.dart';
import 'peer.dart';

enum State {
  connecting,
  connectedIn, // Connected, waiting for CER
  connectedOut, // Connected, waiting for CEA
  tls, // CE completed, negotiating TLS
  ready, // Ready
  closing, // DPR sent, waiting for DPA
  closed // Closed
}

class Connection {
  NodeImplementation nodeImpl;
  Peer? peer; // Initially null
  late String hostId; // Always set, updated from CEA/CER
  late ConnectionTimers timers;
  late ConnectionKey key;
  int hopByHopIdentifierSeq =
      Random().nextInt(0xFFFFFFFF); // Random sequence for hop-by-hop identifier

  late State state;

  Connection(
      NodeImplementation nodeImpl, int watchdogInterval, int idleTimeout) {
    this.nodeImpl = nodeImpl;
    timers = ConnectionTimers(watchdogInterval, idleTimeout);
    key = ConnectionKey();
    state = State.connectedIn;
  }

  // Synchronized method to generate next hop-by-hop identifier
  int nextHopByHopIdentifier() {
    return hopByHopIdentifierSeq++;
  }

  // Abstract methods to be implemented by subclasses

  // Convert to InetAddress
  InetAddress toInetAddress();

  // Send a message with raw byte data
  void sendMessage(List<int> raw);

  // Get relevant node authentication information
  Object getRelevantNodeAuthInfo();

  // Get local addresses
  Collection<InetAddress> getLocalAddresses();

  // Convert to Peer object
  Peer toPeer();

  // Get watchdog interval
  int watchdogInterval() {
    return timers.cfgWatchdogTimer;
  }
}

class ConnectionTimers {
  int cfgWatchdogTimer;
  int cfgIdleTimeout;

  ConnectionTimers(this.cfgWatchdogTimer, this.cfgIdleTimeout);
}



class NodeImplementation {
  // Define node implementation
}


abstract class InetAddress {
  // Define InetAddress class
}
