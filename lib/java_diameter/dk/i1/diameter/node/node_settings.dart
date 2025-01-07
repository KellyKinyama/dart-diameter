import 'capability.dart';

class InvalidSettingException implements Exception {
  final String message;
  InvalidSettingException(this.message);
  
  @override
  String toString() => "InvalidSettingException: $message";
}

class NodeSettings {
  String hostId;
  String realm;
  int vendorId;
  Capability capabilities;
  int port;
  String productName;
  int firmwareRevision;
  late int watchdogInterval;
  late int idleCloseTimeout;
  bool? useTcp;
  bool? useSctp;
  PortRange? portRange;

  NodeSettings({
    required this.hostId,
    required this.realm,
    required this.vendorId,
    required this.capabilities,
    required this.port,
    required this.productName,
    required this.firmwareRevision,
  }) {
    if (hostId.isEmpty || !hostId.contains('.')) {
      throw InvalidSettingException("hostId must contain at least 2 dots");
    }

    if (realm.isEmpty || !realm.contains('.')) {
      throw InvalidSettingException("realm must contain at least 1 dot");
    }

    if (vendorId == 0) {
      throw InvalidSettingException(
        "vendorId must not be zero. Apply for a vendor ID at IANA.");
    }

    if (capabilities.isEmpty) {
      throw InvalidSettingException("Capabilities must be non-empty");
    }

    if (port < 0 || port > 65535) {
      throw InvalidSettingException("port must be in the range 0..65535");
    }

    if (productName.isEmpty) {
      throw InvalidSettingException("productName cannot be null or empty");
    }

    this.watchdogInterval = 30 * 1000; // Default to 30 seconds
    this.idleCloseTimeout = 7 * 24 * 3600 * 1000; // Default to 7 days
  }

  String get hostId => this.hostId;
  String get realm => this.realm;
  int get vendorId => this.vendorId;
  Capability get capabilities => this.capabilities;
  int get port => this.port;
  String get productName => this.productName;
  int get firmwareRevision => this.firmwareRevision;
  int get watchdogInterval => this.watchdogInterval;
  int get idleTimeout => this.idleCloseTimeout;

  void setWatchdogInterval(int interval) {
    if (interval < 6 * 1000) {
      throw InvalidSettingException(
          "watchdog interval must be at least 6 seconds");
    }
    this.watchdogInterval = interval;
  }

  void setIdleTimeout(int timeout) {
    if (timeout < 0) {
      throw InvalidSettingException("idle timeout cannot be negative");
    }
    this.idleCloseTimeout = timeout;
  }

  bool? get useTcp => this.useTcp;
  bool? get useSctp => this.useSctp;

  void setUseTcp(bool? useTcp) {
    this.useTcp = useTcp;
  }

  void setUseSctp(bool? useSctp) {
    this.useSctp = useSctp;
  }

  void setTcpPortRange(PortRange portRange) {
    this.portRange = portRange;
  }

  PortRange? getTcpPortRange() {
    return portRange;
  }

  void setTcpPortRangeFromInts(int min, int max) {
    portRange = PortRange(min, max);
  }
}

class PortRange {
  int min;
  int max;

  PortRange(this.min, this.max) {
    if (min <= 0 || min > max || max >= 65536) {
      throw InvalidSettingException(
          "Invalid port range, 0 < min <= max < 65536");
    }
  }
}
