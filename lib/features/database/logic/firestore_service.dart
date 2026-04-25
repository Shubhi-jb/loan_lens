import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Writes anonymized intelligence data directly to Firestore.
  /// Enforces the opt-in mechanism by strictly requiring `userOptIn == true`.
  static Future<void> logAnonymisedIntelligence({
    required String appName,
    required String biasPatternType,
    required double interestRateDeviation,
    required bool userOptIn,
  }) async {
    if (!userOptIn) {
      debugPrint('User did not opt in. No PII or intelligence data saved.');
      return;
    }

    try {
      await _db.collection('anonymised_intelligence').add({
        'app_name': appName,
        'bias_pattern_type': biasPatternType,
        'interest_rate_deviation': interestRateDeviation,
        'user_opt_in': true, // Strict enforcement mapping to Security Rules
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Successfully logged anonymized intelligence data.');
    } catch (e) {
      debugPrint('Failed to log intelligence: $e');
    }
  }
}
