import 'dart:convert';

/// Represents an error returned by the Spring Boot backend or network layer.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? error;
  final String? path;
  final Map<String, String>? validationErrors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.error,
    this.path,
    this.validationErrors,
  });

  /// Parses standard Spring Boot ErrorResponse or generic error bodies.
  factory ApiException.fromResponse(int statusCode, String body) {
    if (body.isEmpty) {
      return ApiException(
        message: 'Request failed with status $statusCode',
        statusCode: statusCode,
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        // Match Spring Boot ErrorResponse: { status, error, message, path, validationErrors }
        // or ApiResponse: { success, message, data }
        String message = decoded['message'] as String? ??
            decoded['error'] as String? ??
            'Request failed with status $statusCode';

        final error = decoded['error'] as String?;
        final path = decoded['path'] as String?;

        Map<String, String>? validationErrors;
        if (decoded['validationErrors'] is Map) {
          validationErrors = (decoded['validationErrors'] as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        }

        // If validation errors exist, compile a friendly summary message if needed
        if (validationErrors != null && validationErrors.isNotEmpty) {
          final firstError = validationErrors.values.first;
          if (message == 'Validation Failed' || message.contains('Input validation failed')) {
            message = firstError;
          }
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          error: error,
          path: path,
          validationErrors: validationErrors,
        );
      }
    } catch (_) {
      // Body is not JSON
    }

    return ApiException(
      message: 'Server returned error ($statusCode): $body',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}

