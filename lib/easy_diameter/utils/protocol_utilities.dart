import 'dart:math';

import 'protocol_defintions.dart';

class ProtocolUtilities {
  static final AtomicInt receiverCounter = AtomicInt(0);

  static int findAVPHeaderLength(int flags) {
    return (flags & ProtocolDefinitions.AVP_MASK_BIT_V) == 0 ? ProtocolDefinitions.AVP_HDR_LEN_WITHOUT_VENDOR : ProtocolDefinitions.AVP_HDR_LEN_WITH_VENDOR;
  }

  static int createHopByHopId() {
    final time = DateTime.now().millisecondsSinceEpoch;
    return time % 1000000;
  }

  static int createEndToEndId() {
    final random = Random();
    int e2eId = 0;
    final time = DateTime.now().millisecondsSinceEpoch;

    e2eId |= (random.nextInt(256) << 24);
    e2eId |= (time & 0xFFFFFF);

    return e2eId;
  }
}

class AtomicInt {
  int _value;
  AtomicInt(this._value);

  int get value => _value;

  int add(int increment) {
    _value += increment;
    return _value;
  }

  int increment() => add(1);
}
