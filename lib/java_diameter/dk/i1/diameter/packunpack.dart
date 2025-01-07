class PackUnpack {
  static void pack8(List<int> b, int offset, int value) {
    b[offset] = value & 0xFF;
  }

  static void pack16(List<int> b, int offset, int value) {
    b[offset] = (value >> 8) & 0xFF;
    b[offset + 1] = value & 0xFF;
  }

  static void pack32(List<int> b, int offset, int value) {
    b[offset] = (value >> 24) & 0xFF;
    b[offset + 1] = (value >> 16) & 0xFF;
    b[offset + 2] = (value >> 8) & 0xFF;
    b[offset + 3] = value & 0xFF;
  }

  static void pack64(List<int> b, int offset, int value) {
    b[offset] = (value >> 56) & 0xFF;
    b[offset + 1] = (value >> 48) & 0xFF;
    b[offset + 2] = (value >> 40) & 0xFF;
    b[offset + 3] = (value >> 32) & 0xFF;
    b[offset + 4] = (value >> 24) & 0xFF;
    b[offset + 5] = (value >> 16) & 0xFF;
    b[offset + 6] = (value >> 8) & 0xFF;
    b[offset + 7] = value & 0xFF;
  }

  static int unpack8(List<int> b, int offset) {
    return b[offset] & 0xFF;
  }

  static int unpack16(List<int> b, int offset) {
    return ((b[offset] & 0xFF) << 8) | (b[offset + 1] & 0xFF);
  }

  static int unpack32(List<int> b, int offset) {
    return ((b[offset] & 0xFF) << 24) |
        ((b[offset + 1] & 0xFF) << 16) |
        ((b[offset + 2] & 0xFF) << 8) |
        (b[offset + 3] & 0xFF);
  }

  static int unpack64(List<int> b, int offset) {
    return ((b[offset] & 0xFF) << 56) |
        ((b[offset + 1] & 0xFF) << 48) |
        ((b[offset + 2] & 0xFF) << 40) |
        ((b[offset + 3] & 0xFF) << 32) |
        ((b[offset + 4] & 0xFF) << 24) |
        ((b[offset + 5] & 0xFF) << 16) |
        ((b[offset + 6] & 0xFF) << 8) |
        (b[offset + 7] & 0xFF);
  }
}
