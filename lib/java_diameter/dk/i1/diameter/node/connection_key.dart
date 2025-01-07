/// A connection identifier.
/// 
/// `ConnectionKey` is used to refer to a specific connection. It can be used
/// to remember where a request came from and later send a response to it.
/// If the connection is lost in the meantime, the system will not recognize
/// the `ConnectionKey` and reject sending the message.
class ConnectionKey {
  static int _sequence = 0;
  final int _id;

  /// Constructor that initializes a unique connection identifier.
  ConnectionKey() : _id = _nextId();

  /// Generates the next unique identifier.
  static int _nextId() {
    return _sequence++;
  }

  @override
  int get hashCode => _id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConnectionKey) return false;
    return other._id == _id;
  }
}
