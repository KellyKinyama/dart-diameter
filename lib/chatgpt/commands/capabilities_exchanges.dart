import 'dart:typed_data';
import 'dart:convert';

import '../avp9.dart';

class CapabilitiesExchange {
  static const int code = 257;
  final List<DiameterAVP> avps;

  CapabilitiesExchange(this.avps);

  Uint8List encode() {
    final groupedAVP = GroupedAVP(avps);
    final header = DiameterAVPHeader(
      code: code,
      flags: DiameterAVPFlags.fromAvpFlags(
        isMandatory: true,
        isPrivate: false,
        isVendor: false,
      ),
      length: groupedAVP.value.length + 8,
    );
    final diameterAvp = DiameterAVP(
      header: header,
      payload: groupedAVP,
    );
    return diameterAvp.encode();
  }

  static CapabilitiesExchange decode(Uint8List data) {
    final diameterAvp = DiameterAVP.decode(data);
    final groupedAVP = diameterAvp.payload as GroupedAVP;
    return CapabilitiesExchange(groupedAVP.avps);
  }
}

class CapabilitiesExchangeAnswer extends CapabilitiesExchange {
  CapabilitiesExchangeAnswer(List<DiameterAVP> avps) : super(avps);

  factory CapabilitiesExchangeAnswer.fromAttributes({
    required int resultCode,
    required String originHost,
    required String originRealm,
    List<String> hostIpAddress = const [],
    int? vendorId,
    String? productName,
    int? originStateId,
    String? errorMessage,
    //FailedAvp? failedAvp,
    List<int>? supportedVendorId,
    List<int>? authApplicationId,
    List<int>? inbandSecurityId,
    List<int>? acctApplicationId,
    List<DiameterAVP>? customAvps,
  }) {
    final avps = <DiameterAVP>[
      DiameterAVP(
        header: DiameterAVPHeader(
          code: 268,
          flags: DiameterAVPFlags.fromAvpFlags(
            isMandatory: true,
            isPrivate: false,
            isVendor: false,
          ),
          length: 12,
        ),
        payload: IntegerAVP(resultCode),
      ),
      DiameterAVP(
        header: DiameterAVPHeader(
          code: 264,
          flags: DiameterAVPFlags.fromAvpFlags(
            isMandatory: true,
            isPrivate: false,
            isVendor: false,
          ),
          length: originHost.length + 8,
        ),
        payload: StringAVP(originHost),
      ),
      DiameterAVP(
        header: DiameterAVPHeader(
          code: 296,
          flags: DiameterAVPFlags.fromAvpFlags(
            isMandatory: true,
            isPrivate: false,
            isVendor: false,
          ),
          length: originRealm.length + 8,
        ),
        payload: StringAVP(originRealm),
      ),
    ];

    if (customAvps != null) avps.addAll(customAvps);

    return CapabilitiesExchangeAnswer(avps);
  }
}

class CapabilitiesExchangeRequest extends CapabilitiesExchange {
  CapabilitiesExchangeRequest(List<DiameterAVP> avps) : super(avps);

  factory CapabilitiesExchangeRequest.fromAttributes({
    required String originHost,
    required String originRealm,
    List<String> hostIpAddress = const [],
    int? vendorId,
    String? productName,
    int? originStateId,
    List<int>? supportedVendorId,
    List<int>? authApplicationId,
    List<int>? inbandSecurityId,
    List<int>? acctApplicationId,
    List<DiameterAVP>? customAvps,
  }) {
    final avps = <DiameterAVP>[
      DiameterAVP(
        header: DiameterAVPHeader(
          code: 264,
          flags: DiameterAVPFlags.fromAvpFlags(
            isMandatory: true,
            isPrivate: false,
            isVendor: false,
          ),
          length: originHost.length + 8,
        ),
        payload: StringAVP(originHost),
      ),
      DiameterAVP(
        header: DiameterAVPHeader(
          code: 296,
          flags: DiameterAVPFlags.fromAvpFlags(
            isMandatory: true,
            isPrivate: false,
            isVendor: false,
          ),
          length: originRealm.length + 8,
        ),
        payload: StringAVP(originRealm),
      ),
    ];

    if (customAvps != null) avps.addAll(customAvps);

    return CapabilitiesExchangeRequest(avps);
  }
}

// Example for testing
void main() {
  final request = CapabilitiesExchangeRequest.fromAttributes(
    originHost: 'example.com',
    originRealm: 'realm.example.com',
  );

  final encodedRequest = request.encode();
  print('Encoded Request: $encodedRequest');

  final decodedRequest = CapabilitiesExchange.decode(encodedRequest);
  print('Decoded Request AVPs: ${decodedRequest.avps}');
}
