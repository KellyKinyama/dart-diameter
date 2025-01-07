import 'dart:typed_data'; // For ByteBuffer

abstract class ConnectionBuffers {
  ByteBuffer netOutBuffer();
  ByteBuffer netInBuffer();
  ByteBuffer appInBuffer();
  ByteBuffer appOutBuffer();
  void processNetInBuffer();
  void processAppOutBuffer();

  void makeSpaceInNetInBuffer();
  void makeSpaceInAppOutBuffer(int howMuch);

  void consumeNetOutBuffer(int bytes) {
    consume(netOutBuffer(), bytes);
  }

  void consumeAppInBuffer(int bytes) {
    consume(appInBuffer(), bytes);
  }

  static ByteBuffer makeSpaceInBuffer(ByteBuffer bb, int howMuch) {
    if (bb.position + howMuch > bb.lengthInBytes) {
      int bytes = bb.position;
      int newCapacity = bb.lengthInBytes + howMuch;
      newCapacity = newCapacity + (4096 - (newCapacity % 4096));
      var tmp = ByteBuffer.allocate(newCapacity);
      tmp.setRange(0, bb.position, bb.asUint8List());
      tmp.position = bytes;
      bb = tmp;
    }
    return bb;
  }

  static void consume(ByteBuffer bb, int bytes) {
    bb.limit = bb.position;
    bb.position = bytes;
    bb.compact();
  }
}
