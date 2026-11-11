import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import 'api_exception.dart';
import 'vehicle_api_service.dart';

/// Distinct UI states for the vehicle data layer.
enum VehicleListState {
  initial,
  loading,
  success,
  error,
}

/// Central state manager / view-model for vehicles.
///
/// Keeps widgets clean and free of HTTP or serialization code.
class VehicleService extends ChangeNotifier {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;

  final VehicleApiService _api;

  VehicleService._internal({VehicleApiService? api})
      : _api = api ?? VehicleApiService();

  VehicleListState _state = VehicleListState.initial;
  List<Vehicle> _vehicles = [];
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters for UI State
  // ---------------------------------------------------------------------------

  VehicleListState get state => _state;
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == VehicleListState.loading;
  bool get hasError => _state == VehicleListState.error;
  bool get isSuccess => _state == VehicleListState.success;
  bool get isEmpty => _state == VehicleListState.success && _vehicles.isEmpty;

  // ---------------------------------------------------------------------------
  // Metrics for Fleet Dashboard
  // ---------------------------------------------------------------------------

  int get totalCount => _vehicles.length;

  int get activeCount =>
      _vehicles.where((v) => v.status.toUpperCase() == 'ACTIVE').length;

  int get maintenanceCount =>
      _vehicles.where((v) => v.status.toUpperCase() == 'MAINTENANCE').length;

  int get inactiveCount =>
      _vehicles.where((v) => v.status.toUpperCase() == 'INACTIVE').length;

  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Fetches all vehicles from the backend REST API.
  Future<void> fetchVehicles() async {
    _state = VehicleListState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicles = await _api.getVehicles();
      _state = VehicleListState.success;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = VehicleListState.error;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _state = VehicleListState.error;
    }

    notifyListeners();
  }

  /// Creates a new vehicle in the database via POST /api/v1/vehicles.
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      final created = await _api.createVehicle(vehicle);
      _vehicles = [created, ..._vehicles];
      _state = VehicleListState.success;
      _errorMessage = null;
      notifyListeners();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing vehicle via PUT /api/v1/vehicles/{id}.
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    if (vehicle.id == null) {
      throw const ApiException(message: 'Vehicle ID is required for update');
    }

    try {
      final updated = await _api.updateVehicle(vehicle.id!, vehicle);
      final index = _vehicles.indexWhere((v) => v.id == updated.id);
      if (index != -1) {
        final list = List<Vehicle>.from(_vehicles);
        list[index] = updated;
        _vehicles = list;
      }
      _state = VehicleListState.success;
      _errorMessage = null;
      notifyListeners();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a vehicle by ID via DELETE /api/v1/vehicles/{id}.
  Future<void> deleteVehicle(int id) async {
    try {
      await _api.deleteVehicle(id);
      _vehicles = _vehicles.where((v) => v.id != id).toList();
      _state = VehicleListState.success;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

