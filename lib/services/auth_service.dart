import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_session.dart';
import 'api_exception.dart';

/// Service managing user authentication, session state, and security headers.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final http.Client _client;

  AuthService._internal({http.Client? client}) : _client = client ?? http.Client();

  UserSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  UserSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null && _currentSession!.isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns security headers required by backend for protected vehicle operations.
  Map<String, String> get authHeaders {
    final headers = <String, String>{};
    if (_currentSession?.token != null && _currentSession!.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_currentSession!.token}';
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // Authentication Actions
  // ---------------------------------------------------------------------------

  /// Authenticates user against Spring Boot REST API.
  ///
  /// Strictly requires HTTP 200 OK from the backend to create a session and return true.
  /// Rejects navigation and throws [ApiException] with 'Invalid username or password'
  /// if the backend returns 401 Unauthorized or any other error.
  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final trimmedIdentifier = usernameOrEmail.trim();
    final trimmedPassword = password.trim();

    if (trimmedIdentifier.isEmpty || trimmedPassword.isEmpty) {
      _isLoading = false;
      _errorMessage = 'Invalid username or password';
      notifyListeners();
      throw const ApiException(
        message: 'Invalid username or password',
        statusCode: 400,
      );
    }

    try {
      final loginUri = Uri.parse(ApiConfig.authLogin);
      http.Response response;

      try {
        response = await _client.post(
          loginUri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'username': trimmedIdentifier,
            'email': trimmedIdentifier,
            'password': trimmedPassword,
          }),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        // If /api/v1/auth/login failed to connect or timed out, attempt alternate path
        try {
          final altUri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');
          response = await _client.post(
            altUri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': trimmedIdentifier,
              'email': trimmedIdentifier,
              'password': trimmedPassword,
            }),
          ).timeout(const Duration(seconds: 4));
        } catch (_) {
          throw ApiException(
            message:
                'Unable to connect to Spring Boot server at ${ApiConfig.baseUrl}. Please verify the backend is running.',
            statusCode: 503,
          );
        }
      }

      // If primary endpoint returned 404, check alternate path as well
      if (response.statusCode == 404) {
        try {
          final altResponse = await _client.post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': trimmedIdentifier,
              'email': trimmedIdentifier,
              'password': trimmedPassword,
            }),
          ).timeout(const Duration(seconds: 4));
          if (altResponse.statusCode == 200 || altResponse.statusCode == 401) {
            response = altResponse;
          }
        } catch (_) {}
      }

      // STRICT CHECK: ONLY proceed if backend HTTP response is 200 OK
      if (response.statusCode == 200) {
        String? token;
        String role = 'ADMIN';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            token = decoded['token'] as String? ??
                decoded['accessToken'] as String? ??
                (decoded['data'] is Map ? decoded['data']['token'] as String? : null);
            role = (decoded['role'] as String?) ??
                (decoded['data'] is Map ? decoded['data']['role'] as String? : null) ??
                'ADMIN';
          }
        } catch (_) {
          // Response body was not JSON, but status is 200 OK
        }

        _currentSession = UserSession(
          username: trimmedIdentifier.contains('@') ? trimmedIdentifier.split('@').first : trimmedIdentifier,
          email: trimmedIdentifier.contains('@') ? trimmedIdentifier : '$trimmedIdentifier@vms.com',
          token: token ?? 'vms-session-token',
          role: role,
          loginTime: DateTime.now(),
        );

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      // Handle 401 Unauthorized and 403 Forbidden
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ApiException(
          message: 'Invalid username or password',
          statusCode: 401,
        );
      }

      // For any other non-200 status code, parse message or reject with "Invalid username or password"
      String errorMsg = 'Invalid username or password';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['message'] != null && decoded['message'].toString().isNotEmpty) {
            final msg = decoded['message'].toString();
            if (msg.toLowerCase().contains('unauthorized') ||
                msg.toLowerCase().contains('invalid') ||
                msg.toLowerCase().contains('bad credentials')) {
              errorMsg = 'Invalid username or password';
            } else {
              errorMsg = msg;
            }
          }
        }
      } catch (_) {}

      throw ApiException(
        message: errorMsg,
        statusCode: response.statusCode,
      );
    } on ApiException catch (e) {
      _isLoading = false;
      _currentSession = null;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _currentSession = null;
      _errorMessage = 'Invalid username or password';
      notifyListeners();
      throw const ApiException(
        message: 'Invalid username or password',
        statusCode: 401,
      );
    }
  }

  /// Logs out user, invalidates session, and notifies listeners.
  void logout() {
    _currentSession = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Triggered when protected vehicle operations return 401 Unauthorized or 403 Forbidden.
  void handleUnauthorized() {
    _currentSession = null;
    _errorMessage = 'Session expired. Please log in again.';
    notifyListeners();
  }
}
