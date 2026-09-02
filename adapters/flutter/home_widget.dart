// Preview adapter for home_widget (Android/iOS plugin). There is no home
// screen widget in a preview; everything is a no-op that reports success.
class HomeWidget {
  static Future<bool?> setAppGroupId(String groupId) async => true;
  static Future<bool?> saveWidgetData<T>(String id, T? data) async => true;
  static Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) async => true;
}
