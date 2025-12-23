import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logScore(int score, String theme) async {
    await _analytics.logEvent(
      name: 'quiz_complete',
      parameters: {
        'score': score,
        'theme': theme,
      },
    );
  }

  static Future<void> setPreferredTheme(String? theme) async {
    await _analytics.setUserProperty(
      name: 'preferred_theme',
      value: theme,
    );
  }
}
