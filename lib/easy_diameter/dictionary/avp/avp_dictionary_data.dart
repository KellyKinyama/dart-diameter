//import 'package:your_project/avp_factory.dart'; // Adjust import as needed
//import 'package:your_project/protocol_definitions.dart';

import '../../packet/avp/factory/avp_factory.dart'; // Adjust import as needed

class AVPDictionaryData {
  final int code;
  final int flags;
  final int vendorId;
  final String name;

  AVPDictionaryData({
    required this.code,
    required this.flags,
    required this.vendorId,
    required this.name,
  });

  // For your use case, implement how the data is retrieved for a dictionary entry
  static AVPDictionaryData getDictionaryData(int code, int vendorId) {
    // Replace this logic with the actual implementation
    return AVPDictionaryData(
        code: code, flags: 0, vendorId: vendorId, name: 'Sample AVP');
  }
}
