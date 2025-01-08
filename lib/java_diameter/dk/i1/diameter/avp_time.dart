import 'dart:typed_data';
import 'avp.dart';
import 'avp_unsinged32.dart';

class AVP_Time extends AVP_Unsigned32 {
  static const int secondsBetween1900And1970 = ((70 * 365) + 17) * 86400;

  // Constructor that copies another AVP_Time
  AVP_Time(AVP a) : super(a);

  // Constructor that initializes the AVP with a DateTime value
  AVP_Time.withDate(int code, DateTime value)
      : super.intValue(code,
            (value.millisecondsSinceEpoch ~/ 1000) + secondsBetween1900And1970);

  // Constructor that initializes the AVP with a vendor ID and DateTime value
  AVP_Time.withVendorAndDate(int code, int vendorId, DateTime value)
      : super.withVendor(code, vendorId,
            (value.millisecondsSinceEpoch ~/ 1000) + secondsBetween1900And1970);

  // Constructor that initializes the AVP with seconds since 1970
  AVP_Time.withSecondsSince1970(int code, int secondsSince1970)
      : super.intValue(code, secondsSince1970 + secondsBetween1900And1970);

  // Constructor that initializes the AVP with a vendor ID and seconds since 1970
  AVP_Time.withVendorAndSecondsSince1970(
      int code, int vendorId, int secondsSince1970)
      : super.withVendor(
            code, vendorId, secondsSince1970 + secondsBetween1900And1970);

  // Query the DateTime value by converting from seconds
  DateTime queryDate() {
    return DateTime.fromMillisecondsSinceEpoch(
        (queryValue() - secondsBetween1900And1970) * 1000);
  }

  // Query the seconds since 1970
  int querySecondsSince1970() {
    return queryValue() - secondsBetween1900And1970;
  }

  // Set the payload value to a DateTime
  // void setValue(DateTime value) {
  //   setPayload(Uint8List.fromList([
  //     _dateToSeconds(value)
  //   ])); // Assuming AVP expects a single value as the payload
  // }

  // Override setValue to handle DateTime (convert DateTime to seconds)
  @override
  void setValue(int value) {
    // Convert DateTime to seconds before setting it as payload
    setPayload(Uint8List.fromList(
        [value])); // Assuming AVP expects a single value as the payload
  }

  // Helper method to convert DateTime to seconds
  static int _dateToSeconds(DateTime value) {
    return (value.millisecondsSinceEpoch ~/ 1000) + secondsBetween1900And1970;
  }
}
