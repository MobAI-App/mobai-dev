// Preview adapter for device_info_plus. The real plugin answers on macOS, but
// the preview steers an app down its iOS branch, where `iosInfo` would be
// parsed from a macOS payload and throw. Fixed values instead.
enum BrowserName { unknown, chrome, edge, firefox, msie, opera, safari, samsungInternet }

class WebBrowserInfo {
  const WebBrowserInfo({this.browserName = BrowserName.unknown});
  final BrowserName browserName;
}

class AndroidBuildVersion {
  const AndroidBuildVersion({this.sdkInt = 34});
  final int sdkInt;
}

class AndroidDeviceInfo {
  const AndroidDeviceInfo({this.brand = 'Preview', this.version = const AndroidBuildVersion(), this.systemFeatures = const <String>[]});
  final String brand;
  final AndroidBuildVersion version;
  final List<String> systemFeatures;
}

class IosDeviceInfo {
  const IosDeviceInfo({this.localizedModel = 'iPhone', this.name = 'Preview iPhone', this.model = 'iPhone', this.systemVersion = '18.0'});
  final String localizedModel;
  final String name;
  final String model;
  final String systemVersion;
}

class MacOsDeviceInfo {
  const MacOsDeviceInfo({this.model = 'Mac', this.computerName = 'Preview Mac'});
  final String model;
  final String computerName;
}

class DeviceInfoPlugin {
  Future<AndroidDeviceInfo> get androidInfo async => const AndroidDeviceInfo();
  Future<IosDeviceInfo> get iosInfo async => const IosDeviceInfo();
  Future<MacOsDeviceInfo> get macOsInfo async => const MacOsDeviceInfo();
  Future<WebBrowserInfo> get webBrowserInfo async => const WebBrowserInfo();
}
