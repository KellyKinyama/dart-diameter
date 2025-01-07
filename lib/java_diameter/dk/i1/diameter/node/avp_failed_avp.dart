import '../avp.dart';
import '../avp_grouped.dart';
import '../protocol_constants.dart';

class AVP_FailedAVP extends AVPGrouped {
  static List<AVP> wrap(AVP a) {
    return [a];
  }

  AVP_FailedAVP(AVP a) : super(ProtocolConstants.DI_FAILED_AVP, wrap(a));
}
