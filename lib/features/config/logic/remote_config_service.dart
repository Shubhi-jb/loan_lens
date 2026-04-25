import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10), // Fail fast if offline to ensure app loads quickly
        minimumFetchInterval: const Duration(hours: 1), 
      ));

      // Add fallback defaults just in case the device is entirely offline on very first launch
      await _remoteConfig.setDefaults(const {
        'rbi_interest_rate_ceilings': '{"personal_loan": 24.0, "microfinance": 26.0}',
        'prompt_templates': 'System: Analyze the text and identify exploitative clauses.',
      });

      // Connect to the Live Firebase Remote Config and pull down ceilings 
      bool updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        debugPrint('RemoteConfigService: Successfully fetched fresh live limits from cloud.');
      } else {
        debugPrint('RemoteConfigService: Cache already fresh or native defaults applied.');
      }
    } catch (e) {
      debugPrint('RemoteConfigService Offline Fallback Triggered. Relying entirely on safe defaults. Error: $e');
    }
  }

  static String get rbiInterestRateCeilings =>
      _remoteConfig.getString('rbi_interest_rate_ceilings');

  static String get promptTemplates =>
      _remoteConfig.getString('prompt_templates');
}
