import 'dart:typed_data';

import 'avp.dart';
import 'avp_unsinged32.dart';

class AVP_Time extends AVP_Unsigned32 {
  static const int secondsBetween1900And1970 = ((70 * 365) + 17) * 86400;

  AVP_Time(AVP a) : super(a);

  AVP_Time.withDate(int code, DateTime value) : super.intValue(code, (value.millisecondsSinceEpoch ~/ 1000) + secondsBetween1900And1970);

  AVP_Time.withVendorAndDate(int code, int vendorId, DateTime value)
      : super.withVendor(code, vendorId, (value.millisecondsSinceEpoch ~/ 1000) + secondsBetween1900And1970);

  AVP_Time.withSecondsSince1970(int code, int secondsSince1970) : super.intValue(code, secondsSince1970 + secondsBetween1900And1970);

  AVP_Time.withVendorAndSecondsSince1970(int code, int vendorId, int secondsSince1970)
      : super.withVendor(code, vendorId, secondsSince1970 + secondsBetween1900And1970);

  DateTime queryDate() {
    return DateTime.fromMillisecondsSinceEpoch((queryValue() - secondsBetween1900And1970) * 1000);
  }

  int querySecondsSince1970() {
    return queryValue() - secondsBetween1900And1970;
  }

  void setValue(DateTime value) {
    setPayload(Uint8List.fromList([_dateToSeconds(value)]));
  }

  static int _dateToSeconds(DateTime value) {
    return (value.millisecondsSinceEpoch ~/ 1000) + secondsBetween1900And1970;
  }
}
