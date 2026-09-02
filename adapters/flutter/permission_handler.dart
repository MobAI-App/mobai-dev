// Preview adapter for permission_handler: every permission is granted.
import 'dart:async';

enum PermissionStatus { denied, granted, restricted, limited, permanentlyDenied, provisional }

extension PermissionStatusGetters on PermissionStatus {
  bool get isGranted => this == PermissionStatus.granted;
  bool get isDenied => this == PermissionStatus.denied;
  bool get isPermanentlyDenied => this == PermissionStatus.permanentlyDenied;
  bool get isRestricted => this == PermissionStatus.restricted;
  bool get isLimited => this == PermissionStatus.limited;
}

class Permission {
  const Permission._(this.value);
  final int value;

  static const Permission calendar = Permission._(0);
  static const Permission camera = Permission._(1);
  static const Permission contacts = Permission._(2);
  static const Permission location = Permission._(3);
  static const Permission locationAlways = Permission._(4);
  static const Permission locationWhenInUse = Permission._(5);
  static const Permission mediaLibrary = Permission._(6);
  static const Permission microphone = Permission._(7);
  static const Permission phone = Permission._(8);
  static const Permission photos = Permission._(9);
  static const Permission storage = Permission._(15);
  static const Permission notification = Permission._(17);
  static const Permission bluetooth = Permission._(21);
  static const Permission manageExternalStorage = Permission._(22);
  static const Permission requestInstallPackages = Permission._(24);
  static const Permission nearbyWifiDevices = Permission._(32);

  Future<PermissionStatus> request() async => PermissionStatus.granted;
  Future<PermissionStatus> get status async => PermissionStatus.granted;
  Future<bool> get isGranted async => true;
  Future<bool> get isDenied async => false;
  Future<bool> get isPermanentlyDenied async => false;
  Future<bool> get shouldShowRequestRationale async => false;
}

extension PermissionListActions on List<Permission> {
  Future<Map<Permission, PermissionStatus>> request() async =>
      <Permission, PermissionStatus>{for (final p in this) p: PermissionStatus.granted};
}

Future<bool> openAppSettings() async => true;
