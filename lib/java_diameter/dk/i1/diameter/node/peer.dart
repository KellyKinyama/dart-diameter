import 'dart:io';
// import 'dart:net';
// import 'dart:uri';
import 'dart:collection';

class Peer {
  String host;
  int port;
  bool secure;
  TransportProtocol transportProtocol;

  // Enum for TransportProtocol
  static const TransportProtocol tcp = TransportProtocol._('tcp');
  static const TransportProtocol sctp = TransportProtocol._('sctp');
  
  // Constructor for Peer with InetAddress (deprecated)
  Peer.fromAddress(InternetAddress address)
      : this._(address.address, 3868, TransportProtocol.tcp);

  // Constructor for Peer with InetAddress and TransportProtocol (deprecated)
  Peer.fromAddressWithProtocol(InternetAddress address, TransportProtocol transportProtocol)
      : this._(address.address, 3868, transportProtocol);

  // Constructor with InetAddress, port, and TransportProtocol (deprecated)
  Peer.fromAddressWithPort(InternetAddress address, int port)
      : this._(address.address, port, TransportProtocol.tcp);

  // Constructor with InetAddress, port, and TransportProtocol (deprecated)
  Peer.fromAddressWithPortAndProtocol(InternetAddress address, int port, TransportProtocol transportProtocol)
      : this._(address.address, port, transportProtocol);

  // Constructor with hostname (FQDN preferred)
  Peer.fromHost(String host)
      : this._(host, 3868, TransportProtocol.tcp);

  // Constructor with hostname and port
  Peer.fromHostWithPort(String host, int port)
      : this._(host, port, TransportProtocol.tcp);

  // Constructor with hostname, port, and TransportProtocol
  Peer.fromHostWithPortAndProtocol(String host, int port, TransportProtocol transportProtocol)
      : this._(host, port, transportProtocol);

  // Constructor with socket address (deprecated)
  Peer.fromSocketAddress(InternetAddress address, int port)
      : this._(address.address, port, TransportProtocol.tcp);

  // Constructor from URI (aaas or aaa scheme)
  Peer.fromURI(Uri uri) {
    if (uri.scheme != 'aaa' && uri.scheme != 'aaas') {
      throw UnsupportedURIException('Only aaa: schemes are supported');
    }
    if (uri.userInfo != null) {
      throw UnsupportedURIException('Userinfo not supported in Diameter URIs');
    }
    if (uri.path != null && uri.path.isNotEmpty) {
      throw UnsupportedURIException('Path not supported in Diameter URIs');
    }
    host = uri.host;
    port = uri.port == -1 ? 3868 : uri.port;
    secure = uri.scheme == 'aaas';
    transportProtocol = TransportProtocol.tcp;
  }

  // Copy constructor (deep copy)
  Peer.copy(Peer p)
      : host = p.host,
        port = p.port,
        secure = p.secure,
        transportProtocol = p.transportProtocol;

  // URI method to return the Diameter URI of the peer
  Uri uri() {
    return Uri(
      scheme: secure ? 'aaas' : 'aaa',
      host: host,
      port: port,
    );
  }

  // Create Peer from URI string
  static Peer fromURIString(String s) {
    String? extraStuff;
    int index = s.indexOf(';');
    if (index != -1) {
      extraStuff = s.substring(index + 1);
      s = s.substring(0, index);
    }
    Uri uri = Uri.parse(s);
    Peer p = Peer.fromURI(uri);
    if (extraStuff != null) {
      var tokens = extraStuff.split(';');
      for (var token in tokens) {
        var parts = token.split('=');
        if (parts.isNotEmpty && parts[0] == 'transport') {
          if (parts[1] == 'sctp') {
            p.transportProtocol = TransportProtocol.sctp;
          } else if (parts[1] == 'tcp') {
            p.transportProtocol = TransportProtocol.tcp;
          } else {
            throw UnsupportedURIException('Unknown transport-protocol: ${parts[1]}');
          }
        }
      }
    }
    return p;
  }

  // Private constructor to initialize common fields
  Peer._(this.host, this.port, this.transportProtocol) : secure = false;

  @override
  String toString() {
    return '${secure ? 'aaas' : 'aaa'}://$host:$port${transportProtocol == TransportProtocol.tcp ? '' : ';transport=sctp'}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Peer) return false;
    return host == other.host && port == other.port;
  }

  @override
  int get hashCode => host.hashCode ^ port.hashCode;
}

class TransportProtocol {
  final String value;
  const TransportProtocol._(this.value);
}

class UnsupportedURIException implements Exception {
  final String message;
  UnsupportedURIException(this.message);
}
