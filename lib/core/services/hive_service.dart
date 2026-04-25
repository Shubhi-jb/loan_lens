import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String settingsBoxName = 'user_settings';
  
  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(settingsBoxName);
  }

  // Generic getter/setter for preferences
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(settingsBoxName);
    return box.get(key, defaultValue: defaultValue);
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(key, value);
  }
}
