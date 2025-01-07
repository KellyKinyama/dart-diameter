import '../message.dart';
import 'connection_key.dart';
import 'peer.dart';

/// An incoming message dispatcher.
/// A `MessageDispatcher` is used by the `Node` class to dispatch incoming messages.
/// Low-level house-keeping Diameter messages (CEx/DPx/DWx) are not dispatched
/// to it but are instead handled by the Node directly.
///
/// Please note that the `handle()` method is called by the networking thread, and
/// messages from other peers cannot be received until the method returns. If
/// the `handle()` method needs to do any lengthy processing, it should
/// implement a message queue, put the message into the queue, and return.
///
/// Also note that CER/CEA, DWR/DWA, and DPR/DPA messages are given to the
/// dispatcher because the node handles them itself. STR/STA, ASR/ASA, and
/// other base messages are given to the dispatcher.
abstract class MessageDispatcher {
  /// This method is called when the Node has received a message.
  ///
  /// [msg] The incoming message.
  /// [connKey] The connection key.
  /// [peer] The peer of the connection. This is not necessarily the host that originated the message (the message can have gone via proxies).
  ///
  /// Returns `true` if the message was processed. `false` otherwise, in which case the Node will respond with an error to the peer (if the message was a request).
  bool handle(Message msg, ConnectionKey connKey, Peer peer);
}
