import 'dart:math';

class NodeState {
  late final int stateId;
  late int endToEndIdentifier;
  late int sessionIdHigh;
  late int sessionIdLow; // long because we need 32 unsigned bits

  NodeState() {
    int now = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
    stateId = now;
    endToEndIdentifier = (now << 20) | (Random().nextInt(0x000FFFFF));
    sessionIdHigh = now;
    sessionIdLow = 0;
  }

  int getStateId() => stateId;

  int nextEndToEndIdentifier() {
    int value = endToEndIdentifier;
    endToEndIdentifier++;
    return value;
  }

  String nextSessionIdSecondPart() {
    int h = sessionIdHigh;
    int l = sessionIdLow;
    sessionIdLow++;
    if (sessionIdLow == 4294967296) {
      sessionIdLow = 0;
      sessionIdHigh++;
    }
    return '$h;$l';
  }
}
