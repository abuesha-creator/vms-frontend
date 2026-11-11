import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/vehicle.dart';
import 'api_exception.dart';
import 'auth_service.dart';

/// Clean API client isolating raw HTTP communication with Spring Boot.
///
/// Base URL is provided dynamically by [ApiConfig].
class VehicleApiService {
  final http.Client _client;

  VehicleApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    // Attach authorization headers according to backend authentication mechanism
    headers.addAll(AuthService().authHeaders);
    return headers;
  }

  void _checkAuthResponse(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      AuthService().handleUnauthorized();
    }
  }

  /// Fetches all vehicles from `GET /api/v1/vehicles`.
  Future<List<Vehicle>> getVehicles() async {
    final uri = Uri.parse(ApiConfig.vehicles);
    try {
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final list = decoded['data'] as List<dynamic>;
          return list
              .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (decoded is List) {
          return decoded
              .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        _checkAuthResponse(response.statusCode);
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Could not connect to backend server at ${ApiConfig.baseUrl}. Please verify the server is running.',
      );
    }
  }

  /// Fetches a single vehicle by ID from `GET /api/v1/vehicles/{id}`.
  Future<Vehicle> getVehicleById(int id) async {
    final uri = Uri.parse(ApiConfig.vehicle(id));
    try {
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return Vehicle.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return Vehicle.fromJson(decoded as Map<String, dynamic>);
      } else {
        _checkAuthResponse(response.statusCode);
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch vehicle details: $e',
      );
    }
  }

  /// Creates a new vehicle via `POST /api/v1/vehicles`.
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final uri = Uri.parse(ApiConfig.vehicles);
    final bodyJson = jsonEncode(vehicle.toCreateJson());

    try {
      final response = await _client.post(
        uri,
        headers: _headers,
        body: bodyJson,
      );

      if (response.statusCode == 201 || (response.statusCode >= 200 && response.statusCode < 300)) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return Vehicle.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return Vehicle.fromJson(decoded as Map<String, dynamic>);
      } else {
        _checkAuthResponse(response.statusCode);
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create vehicle: $e',
      );
    }
  }

  /// Updates an existing vehicle via `PUT /api/v1/vehicles/{id}`.
  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) async {
    final uri = Uri.parse(ApiConfig.vehicle(id));
    final bodyJson = jsonEncode(vehicle.toUpdateJson());

    try {
      final response = await _client.put(
        uri,
        headers: _headers,
        body: bodyJson,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return Vehicle.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return Vehicle.fromJson(decoded as Map<String, dynamic>);
      } else {
        _checkAuthResponse(response.statusCode);
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update vehicle: $e',
      );
    }
  }

  /// Deletes a vehicle by ID via `DELETE /api/v1/vehicles/{id}`.
  Future<void> deleteVehicle(int id) async {
    final uri = Uri.parse(ApiConfig.vehicle(id));

    try {
      final response = await _client.delete(uri, headers: _headers);

      if (response.statusCode == 204 || (response.statusCode >= 200 && response.statusCode < 300)) {
        return;
      } else {
        _checkAuthResponse(response.statusCode);
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete vehicle: $e',
      );
    }
  }
}
