// import 'package:your_project/avp_dictionary.dart'; // Adjust import as needed
// import 'package:your_project/avp.dart'; // Adjust import as needed
// import 'package:your_project/diameter_exception.dart'; // Adjust import as needed
// import 'package:your_project/protocol_definitions.dart';

//import '../../../../base_protocol/diameter_avp.dart';
import '../../../utils/protocol_defintions.dart';
import '../diameter_avp.dart'; // Adjust import as needed

abstract class AVPFactory implements ProtocolDefinitions {
  // Abstract method to create AVP
  DiameterAVP createAVP(int avpCode, int flags, int vendorId);

  DiameterAVP createAVPFromDictionary(AVPDictionaryData dictData);

  // Static method to create AVP from dictionary using avpCode and vendorId
  factory DiameterAVP.createAVPFromDictionary(int avpCode, int vendorId) {
    final dictData = AVPDictionary.getDictionaryData(avpCode, vendorId);
    if (dictData.dataType == ProtocolDefinitions.DT_UNKNOWN) {
      // throw DiameterDictionaryException(
      //   DiameterException.DIAMETER_DICTIONARY_EXCEPTION,
      //   'No such AVP in dictionary',
      // );
      throw ('No such AVP in dictionary',);
    }
    final avp = dictData.factory.createAVPFromDictionary(dictData);
    avp.setName(dictData.name);
    return avp;
  }

  // Static method to get the appropriate AVPFactory based on the AVP code and vendorId
  static AVPFactory getAVPFactory(int code, int vendorId) {
    final dictData = AVPDictionary.getDictionaryData(code, vendorId);
    return getAVPFactoryByDataType(dictData.dataType);
  }

  // Static method to get the AVPFactory based on the data type
  static AVPFactory getAVPFactoryByDataType(int dataType) {
    AVPFactory factory;
    switch (dataType) {
      case ProtocolDefinitions.DT_OCTET_STRING:
        factory = OctetStringAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_INTEGER_32:
        factory = Integer32AVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_INTEGER_64:
        factory = Integer64AVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_UNSIGNED_32:
        factory = Unsigned32AVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_UNSIGNED_64:
        factory = Unsigned64AVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_FLOAT_32:
        factory = Float32AVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_FLOAT_64:
        factory = Float64AVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_GROUPED:
        factory = GroupedAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_ADDRESS:
        factory = AddressAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_TIME:
        factory = TimeAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_UTF8STRING:
        factory = UTF8StringAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_DIAMETER_IDENTITY:
        factory = DiameterIdentityAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_DIAMETER_URI:
        factory = DiameterURIAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_ENUMERATED:
        factory = EnumeratedAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_IP_FILTER_RULE:
        factory = IPFilterRuleAVPFactory.getInstance();
        break;
      case ProtocolDefinitions.DT_QOS_FILTER_RULE:
        factory = QoSFilterRuleAVPFactory.getInstance();
        break;
      default:
        factory = GenericAVPFactory.getInstance();
        break;
    }
    return factory;
  }
}
