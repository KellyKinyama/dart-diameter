import '../protocol_constants.dart';
class VendorApplication {
    int vendorId;
    int applicationId;

    VendorApplication(this.vendorId, this.applicationId);

    @override
    int get hashCode => vendorId + applicationId;

    @override
    bool operator ==(Object other) {
      if (this == other) return true;
      if (other == null || other.runtimeType != this.runtimeType) return false;
      return (other as VendorApplication).vendorId == vendorId &&
          other.applicationId == applicationId;
    }
  }

class Capability {
  

  Set<int> supportedVendor;
  Set<int> authApp;
  Set<int> acctApp;
  Set<VendorApplication> authVendor;
  Set<VendorApplication> acctVendor;

  // Constructor
  Capability()
      : supportedVendor = Set<int>(),
        authApp = Set<int>(),
        acctApp = Set<int>(),
        authVendor = Set<VendorApplication>(),
        acctVendor = Set<VendorApplication>();

  // Copy Constructor (deep copy)
  Capability.copy(Capability c)
      : supportedVendor = Set<int>.from(c.supportedVendor),
        authApp = Set<int>.from(c.authApp),
        acctApp = Set<int>.from(c.acctApp),
        authVendor = Set<VendorApplication>.from(c.authVendor),
        acctVendor = Set<VendorApplication>.from(c.acctVendor);

  // Checks if vendor is supported
  bool isSupportedVendor(int vendorId) {
    return supportedVendor.contains(vendorId);
  }

  // Checks if application is an allowed auth application
  bool isAllowedAuthApp(int app) {
    return authApp.contains(app) ||
        authApp.contains(ProtocolConstants.DIAMETER_APPLICATION_RELAY);
  }

  // Checks if application is an allowed accounting application
  bool isAllowedAcctApp(int app) {
    return acctApp.contains(app) ||
        acctApp.contains(ProtocolConstants.DIAMETER_APPLICATION_RELAY);
  }

  // Checks if vendor-specific application is allowed for auth
  bool isAllowedAuthAppForVendor(int vendorId, int app) {
    return authVendor.contains(VendorApplication(vendorId, app));
  }

  // Checks if vendor-specific application is allowed for accounting
  bool isAllowedAcctAppForVendor(int vendorId, int app) {
    return acctVendor.contains(VendorApplication(vendorId, app));
  }

  // Adds supported vendor
  void addSupportedVendor(int vendorId) {
    supportedVendor.add(vendorId);
  }

  // Adds an authentication application
  void addAuthApp(int app) {
    authApp.add(app);
  }

  // Adds an accounting application
  void addAcctApp(int app) {
    acctApp.add(app);
  }

  // Adds a vendor-specific authentication application
  void addVendorAuthApp(int vendorId, int app) {
    authVendor.add(VendorApplication(vendorId, app));
  }

  // Adds a vendor-specific accounting application
  void addVendorAcctApp(int vendorId, int app) {
    acctVendor.add(VendorApplication(vendorId, app));
  }

  // Checks if no applications are allowed or supported
  bool isEmpty() {
    return authApp.isEmpty && acctApp.isEmpty && authVendor.isEmpty && acctVendor.isEmpty;
  }

  // Calculates the intersection of capabilities between two Capability instances
  static Capability calculateIntersection(Capability us, Capability peer) {
    Capability c = Capability();

    // Compare supported vendors
    for (int vendorId in peer.supportedVendor) {
      if (us.isSupportedVendor(vendorId)) c.addSupportedVendor(vendorId);
    }

    // Compare authentication applications
    for (int app in peer.authApp) {
      if (app == ProtocolConstants.DIAMETER_APPLICATION_RELAY ||
          us.authApp.contains(app) ||
          us.authApp.contains(ProtocolConstants.DIAMETER_APPLICATION_RELAY)) {
        c.addAuthApp(app);
      }
    }

    // Compare accounting applications
    for (int app in peer.acctApp) {
      if (app == ProtocolConstants.DIAMETER_APPLICATION_RELAY ||
          us.acctApp.contains(app) ||
          us.acctApp.contains(ProtocolConstants.DIAMETER_APPLICATION_RELAY)) {
        c.addAcctApp(app);
      }
    }

    // Compare vendor-specific auth applications
    for (VendorApplication va in peer.authVendor) {
      if (us.isAllowedAuthAppForVendor(va.vendorId, va.applicationId)) {
        c.addVendorAuthApp(va.vendorId, va.applicationId);
      }
    }

    // Compare vendor-specific accounting applications
    for (VendorApplication va in peer.acctVendor) {
      if (us.isAllowedAcctAppForVendor(va.vendorId, va.applicationId)) {
        c.addVendorAcctApp(va.vendorId, va.applicationId);
      }
    }

    return c;
  }
}
