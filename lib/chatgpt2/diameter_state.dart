enum DiameterState { closed, waitConnAck, waitCEA, open }

class DiameterNode {
  DiameterState state = DiameterState.closed;

  void handleEvent(DiameterEvent event) {
    switch (state) {
      case DiameterState.closed:
        if (event == DiameterEvent.connect) {
          state = DiameterState.waitConnAck;
        }
        break;
      case DiameterState.waitConnAck:
        if (event == DiameterEvent.connAck) {
          state = DiameterState.waitCEA;
        }
        break;
      case DiameterState.waitCEA:
        if (event == DiameterEvent.ceaReceived) {
          state = DiameterState.open;
        }
        break;
      case DiameterState.open:
        if (event == DiameterEvent.disconnect) {
          state = DiameterState.closed;
        }
        break;
    }
  }
}
