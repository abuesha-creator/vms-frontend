import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/vehicle_plate_badge.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final VehicleService _service = VehicleService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Load vehicles on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _service.fetchVehicles();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showConfigureUrlDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 10),
            Text('Configure API Base URL'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the Spring Boot REST API server address:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://localhost:8080',
                prefixIcon: Icon(Icons.link_rounded, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ApiConfig.reset();
              Navigator.pop(ctx);
              _service.fetchVehicles();
            },
            child: const Text('Reset to Default'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiConfig.baseUrl = newUrl;
              }
              Navigator.pop(ctx);
              _service.fetchVehicles();
            },
            child: const Text('Save & Reload'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Vehicle vehicle) {
    if (vehicle.id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 24),
            SizedBox(width: 10),
            Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to permanently delete this vehicle from the database?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  VehiclePlateBadge(vehicleNumber: vehicle.vehicleNumber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          vehicle.company,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteVehicle(vehicle.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.textPrimary,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                          const SizedBox(width: 10),
                          Text('Vehicle ${vehicle.vehicleNumber} was deleted successfully'),
                        ],
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.error,
                      content: Text('Failed to delete vehicle: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Vehicle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final filteredVehicles = _service.vehicles.where((v) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = query.isEmpty ||
              v.vehicleNumber.toLowerCase().contains(query) ||
              v.brand.toLowerCase().contains(query) ||
              v.model.toLowerCase().contains(query) ||
              v.company.toLowerCase().contains(query) ||
              v.type.toLowerCase().contains(query);
          final matchesStatus = _selectedStatus == null ||
              v.status.toUpperCase() == _selectedStatus!.toUpperCase();
          return matchesSearch && matchesStatus;
        }).toList();

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fleet Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Connected to: ',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                ApiConfig.baseUrl,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _showConfigureUrlDialog,
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Reload from API',
                          color: AppTheme.textPrimary,
                          onPressed: _service.isLoading ? null : () => _service.fetchVehicles(),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Register Vehicle'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Metrics Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 800;
                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  title: 'Total Vehicles',
                                  value: '${_service.totalCount}',
                                  icon: Icons.directions_car_rounded,
                                  iconColor: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatCard(
                                  title: 'Active Fleet',
                                  value: '${_service.activeCount}',
                                  icon: Icons.check_circle_rounded,
                                  iconColor: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  title: 'Under Maintenance',
                                  value: '${_service.maintenanceCount}',
                                  icon: Icons.build_circle_rounded,
                                  iconColor: AppTheme.warning,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatCard(
                                  title: 'Inactive Units',
                                  value: '${_service.inactiveCount}',
                                  icon: Icons.pause_circle_rounded,
                                  iconColor: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Vehicles',
                            value: '${_service.totalCount}',
                            icon: Icons.directions_car_rounded,
                            iconColor: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Active Fleet',
                            value: '${_service.activeCount}',
                            icon: Icons.check_circle_rounded,
                            iconColor: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Under Maintenance',
                            value: '${_service.maintenanceCount}',
                            icon: Icons.build_circle_rounded,
                            iconColor: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Inactive Units',
                            value: '${_service.inactiveCount}',
                            icon: Icons.pause_circle_rounded,
                            iconColor: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. Search and Filtering Bar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search by vehicle number, brand, model, or company...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 32,
                          width: 1,
                          color: AppTheme.border,
                        ),
                        const SizedBox(width: 16),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedStatus,
                            icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppTheme.textSecondary),
                            hint: const Text(
                              'All Statuses',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('All Statuses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              DropdownMenuItem(
                                value: 'ACTIVE',
                                child: Text('Active Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              DropdownMenuItem(
                                value: 'MAINTENANCE',
                                child: Text('Maintenance Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              DropdownMenuItem(
                                value: 'INACTIVE',
                                child: Text('Inactive Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                            ],
                            onChanged: (val) => setState(() => _selectedStatus = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Content Area: Loading, Error, Empty, or Success State
                if (_service.isLoading) ...[
                  // LOADING STATE
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Fetching vehicles from backend API...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ApiConfig.vehicles,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else if (_service.hasError) ...[
                  // ERROR STATE
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.errorBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(
                                Icons.cloud_off_rounded,
                                size: 40,
                                color: AppTheme.error,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Failed to Load Fleet Data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Text(
                                _service.errorMessage ?? 'An error occurred while connecting to the REST API.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.settings_rounded, size: 16),
                                  label: const Text('Configure URL'),
                                  onPressed: _showConfigureUrlDialog,
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Retry Connection'),
                                  onPressed: () => _service.fetchVehicles(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else if (_service.isEmpty) ...[
                  // EMPTY STATE (0 vehicles in database)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No Vehicles Registered Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'The backend database currently contains zero vehicle records.\nRegister your first vehicle to start monitoring.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Register First Vehicle'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // SUCCESS STATE (Table)
                  Card(
                    child: filteredVehicles.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.background,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No vehicles match your search or filter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try adjusting your search query or status filter.',
                                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: (MediaQuery.sizeOf(context).width - 320).clamp(600.0, double.infinity),
                              ),
                              child: DataTable(
                                horizontalMargin: 24,
                                columnSpacing: 28,
                                headingRowHeight: 52,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 64,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Vehicle Number',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Brand & Model',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Company',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Category',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3),
                                    ),
                                  ),
                                ],
                                rows: filteredVehicles.map((vehicle) {
                                  return DataRow(
                                    cells: [
                                      // Vehicle Number (Plate badge)
                                      DataCell(
                                        VehiclePlateBadge(vehicleNumber: vehicle.vehicleNumber),
                                      ),
                                      // Brand & Model
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vehicle.displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              vehicle.type,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Operating Company
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.apartment_rounded, size: 16, color: AppTheme.textSecondary),
                                            const SizedBox(width: 6),
                                            Text(
                                              vehicle.company,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Category / Type
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.background,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Text(
                                            vehicle.type,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Status (Status badge)
                                      DataCell(
                                        StatusBadge(status: vehicle.status),
                                      ),
                                      // Actions
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 18),
                                              tooltip: 'Edit Vehicle',
                                              color: AppTheme.primary,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => VehicleFormScreen(vehicleToEdit: vehicle),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                              tooltip: 'Delete Vehicle',
                                              color: AppTheme.error,
                                              onPressed: () => _confirmDelete(context, vehicle),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
