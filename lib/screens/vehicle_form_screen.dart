import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_exception.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/vehicle_plate_badge.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit;

  const VehicleFormScreen({super.key, this.vehicleToEdit});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _service = VehicleService();

  late TextEditingController _numberController;
  late TextEditingController _companyController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;

  late String _selectedType;
  late String _selectedStatus;

  bool _isSubmitting = false;
  String? _serverError;

  bool get isEditing => widget.vehicleToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;
    _numberController = TextEditingController(text: v?.vehicleNumber ?? '');
    _companyController = TextEditingController(text: v?.company ?? '');
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');

    _selectedType = v?.type.isNotEmpty == true ? v!.type : Vehicle.standardTypes.first;
    _selectedStatus = v?.status.isNotEmpty == true ? v!.status.toUpperCase() : Vehicle.standardStatuses.first;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _companyController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    setState(() => _serverError = null);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please resolve the highlighted errors in the form.'),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final vehicle = Vehicle(
        id: widget.vehicleToEdit?.id,
        vehicleNumber: _numberController.text.trim().toUpperCase(),
        company: _companyController.text.trim(),
        type: _selectedType.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        status: _selectedStatus.trim().toUpperCase(),
      );

      if (isEditing) {
        await _service.updateVehicle(vehicle);
      } else {
        await _service.createVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.textPrimary,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Text(isEditing
                    ? 'Vehicle ${vehicle.vehicleNumber} updated successfully'
                    : 'Vehicle ${vehicle.vehicleNumber} created successfully'),
              ],
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _serverError = e.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(e.message)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverError = 'An unexpected error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle Profile' : 'Register New Vehicle'),
        actions: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Center(
                child: VehiclePlateBadge(
                  vehicleNumber: widget.vehicleToEdit!.vehicleNumber,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Server error banner if submission failed
                  if (_serverError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_rounded, color: AppTheme.error, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Backend Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _serverError!,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                            onPressed: () => setState(() => _serverError = null),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Main Form Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing ? 'Vehicle Specifications & Status' : 'New Fleet Asset Registration',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Parameters match Spring Boot API (/api/v1/vehicles)',
                                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                              if (isEditing)
                                StatusBadge(status: _selectedStatus, isLarge: true),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: AppTheme.border),
                          const SizedBox(height: 24),

                          // Section 1: Vehicle Identifier & Company
                          const Text(
                            '1. Identification & Fleet Ownership',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vehicle Number (Letters, digits, hyphens - immutable when editing)
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _numberController,
                                  enabled: !isEditing,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'Vehicle Number *',
                                    hintText: 'e.g. TRK-001, NYC-4821',
                                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                    helperText: isEditing
                                        ? 'Vehicle number is immutable after creation'
                                        : 'Only letters, numbers, and hyphens (max 50)',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vehicle number is required';
                                    }
                                    final trimmed = value.trim();
                                    if (trimmed.length > 50) {
                                      return 'Must not exceed 50 characters';
                                    }
                                    if (!RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(trimmed)) {
                                      return 'May only contain letters, digits, and hyphens';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Company
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _companyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Company *',
                                    hintText: 'e.g. Stark Transport Ltd',
                                    prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                                    helperText: 'Operating company (max 100)',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Company is required';
                                    }
                                    if (value.trim().length > 100) {
                                      return 'Must not exceed 100 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Section 2: Specifications
                          const Text(
                            '2. Specifications & Classification',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Brand
                              Expanded(
                                child: TextFormField(
                                  controller: _brandController,
                                  decoration: const InputDecoration(
                                    labelText: 'Brand / Manufacturer *',
                                    hintText: 'e.g. Mercedes-Benz, Ford, Toyota',
                                    prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Brand is required';
                                    }
                                    if (value.trim().length > 50) {
                                      return 'Must not exceed 50 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Model
                              Expanded(
                                child: TextFormField(
                                  controller: _modelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Model *',
                                    hintText: 'e.g. Actros 1845, Transit, Camry',
                                    prefixIcon: Icon(Icons.car_rental_rounded, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Model is required';
                                    }
                                    if (value.trim().length > 50) {
                                      return 'Must not exceed 50 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category / Type Dropdown
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: Vehicle.standardTypes.contains(_selectedType)
                                      ? _selectedType
                                      : Vehicle.standardTypes.first,
                                  decoration: const InputDecoration(
                                    labelText: 'Vehicle Type *',
                                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                                  ),
                                  items: Vehicle.standardTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedType = val);
                                  },
                                  validator: (val) => (val == null || val.isEmpty) ? 'Type is required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Operational Status Dropdown
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: Vehicle.standardStatuses.contains(_selectedStatus)
                                      ? _selectedStatus
                                      : Vehicle.standardStatuses.first,
                                  decoration: const InputDecoration(
                                    labelText: 'Operational Status *',
                                    prefixIcon: Icon(Icons.traffic_outlined, size: 20),
                                  ),
                                  items: Vehicle.standardStatuses.map((status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: Row(
                                        children: [
                                          StatusBadge(status: status),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedStatus = val);
                                  },
                                  validator: (val) => (val == null || val.isEmpty) ? 'Status is required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // Form Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              FilledButton.icon(
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded, size: 18),
                                label: Text(
                                  _isSubmitting
                                      ? 'Saving...'
                                      : (isEditing ? 'Update Vehicle' : 'Create Vehicle'),
                                ),
                                onPressed: _isSubmitting ? null : _saveVehicle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
