// Preview adapter for flutter_native_splash (Android/iOS/web plugin).
// There is no native splash in the preview host, so preserve/remove are no-ops.
import 'package:flutter/widgets.dart';

class FlutterNativeSplash {
  static void preserve({required WidgetsBinding widgetsBinding}) {}
  static void remove() {}
}
