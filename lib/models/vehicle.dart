/// Vehicle data model matching the Spring Boot REST API contract exactly.
///
/// Backend resource: `/api/v1/vehicles`
/// DTOs: `CreateVehicleRequest`, `UpdateVehicleRequest`, `VehicleResponse`
class Vehicle {
  final int? id;
  final String vehicleNumber;
  final String company;
  final String type;
  final String brand;
  final String model;
  final String status;

  const Vehicle({
    this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
  });

  /// Factory constructor to deserialize a Vehicle from the backend `VehicleResponse` JSON.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['id'] as num?)?.toInt(),
      vehicleNumber: (json['vehicleNumber'] as String? ?? '').trim(),
      company: (json['company'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? '').trim(),
      brand: (json['brand'] as String? ?? '').trim(),
      model: (json['model'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? 'ACTIVE').trim().toUpperCase(),
    );
  }

  /// Converts this vehicle to the JSON payload required for `POST /api/v1/vehicles` (CreateVehicleRequest).
  Map<String, dynamic> toCreateJson() {
    return {
      'vehicleNumber': vehicleNumber.trim().toUpperCase(),
      'company': company.trim(),
      'type': type.trim(),
      'brand': brand.trim(),
      'model': model.trim(),
      'status': status.trim().toUpperCase(),
    };
  }

  /// Converts this vehicle to the JSON payload required for `PUT /api/v1/vehicles/{id}` (UpdateVehicleRequest).
  ///
  /// Note: [vehicleNumber] is intentionally excluded because it is immutable after creation.
  Map<String, dynamic> toUpdateJson() {
    return {
      'company': company.trim(),
      'type': type.trim(),
      'brand': brand.trim(),
      'model': model.trim(),
      'status': status.trim().toUpperCase(),
    };
  }

  Vehicle copyWith({
    int? id,
    String? vehicleNumber,
    String? company,
    String? type,
    String? brand,
    String? model,
    String? status,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      status: status ?? this.status,
    );
  }

  /// Full display name combining brand and model.
  String get displayName => '$brand $model'.trim();

  /// Formatted status label (e.g. 'Active', 'Maintenance', 'Inactive').
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'MAINTENANCE':
        return 'In Maintenance';
      case 'INACTIVE':
        return 'Inactive';
      default:
        if (status.isEmpty) return 'Unknown';
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  /// Alias for backward compatibility with license plate displays.
  String get licensePlate => vehicleNumber;

  /// Standard vehicle category types used across fleet management.
  static const List<String> standardTypes = [
    'Truck',
    'Van',
    'Sedan',
    'SUV',
    'Bus',
    'Electric',
  ];

  /// Standard operational statuses matching backend conventions.
  static const List<String> standardStatuses = [
    'ACTIVE',
    'MAINTENANCE',
    'INACTIVE',
  ];
}
