/// Configuration for the Spring Boot backend API connection.
///
/// Supports compile-time configuration via `--dart-define`:
/// ```bash
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
/// flutter build web --dart-define=API_BASE_URL=https://api.vms.production.com
/// ```
/// Also supports runtime modification via [ApiConfig.baseUrl] setter.
class ApiConfig {
  static const String _defaultBaseUrl = 'http://localhost:8080';

  static String? _customBaseUrl;

  /// Returns the active API base URL without any trailing slash.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultBaseUrl,
    ).replaceAll(RegExp(r'/+$'), '');
  }

  /// Sets a custom base URL at runtime.
  static set baseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Resets to the compile-time default base URL.
  static void reset() {
    _customBaseUrl = null;
  }

  // ---------------------------------------------------------------------------
  // Endpoints matching Spring Boot Backend
  // ---------------------------------------------------------------------------

  /// GET /api/health
  static String get health => '$baseUrl/api/health';

  /// POST /api/v1/auth/login (if backend provides auth controller)
  static String get authLogin => '$baseUrl/api/v1/auth/login';

  /// GET /api/v1/vehicles | POST /api/v1/vehicles
  static String get vehicles => '$baseUrl/api/v1/vehicles';

  /// GET /api/v1/vehicles/{id} | PUT /api/v1/vehicles/{id} | DELETE /api/v1/vehicles/{id}
  static String vehicle(int id) => '$baseUrl/api/v1/vehicles/$id';
}
