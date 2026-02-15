/// App-wide constants
class AppConstants {
  // API
  static const String baseUrl = 'http://localhost:8000';
  static const String apiPrefix = '/api/v1';
  static const String wsUrl = 'ws://localhost:8000/api/v1';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_complete';

  // Pagination
  static const int defaultPageSize = 20;

  // Image
  static const String placeholderImage =
      'https://via.placeholder.com/300x300.png?text=No+Image';
  static const double maxImageSize = 5 * 1024 * 1024; // 5MB

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
