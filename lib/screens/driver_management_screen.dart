import 'package:flutter/material.dart';
import '../services/fleet_ops_service.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  List<dynamic> _drivers = [];
  List<Vehicle> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final drivers = await FleetOpsService.getDrivers();
      final vehicleService = VehicleService();
      await vehicleService.fetchVehicles();
      if (!mounted) return;
      setState(() {
        _drivers = drivers;
        _vehicles = vehicleService.vehicles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showAddDriverDialog() {
    final nameCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            const SizedBox(height: 8),
            TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: 'License Number')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FleetOpsService.createDriver({
                  'name': nameCtrl.text,
                  'licenseNumber': licenseCtrl.text,
                  'phone': phoneCtrl.text,
                  'status': 'AVAILABLE',
                });
                if (!mounted) return;
                Navigator.of(context).pop();
                _loadData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(int driverId) {
    int? selectedVehicleId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Vehicle to Driver'),
        content: DropdownButtonFormField<int>(
          hint: const Text('Select a Vehicle'),
          items: _vehicles
              .where((v) => v.id != null)
              .map((v) => DropdownMenuItem(value: v.id, child: Text('${v.vehicleNumber} (${v.brand})')))
              .toList(),
          onChanged: (val) => selectedVehicleId = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedVehicleId == null) return;
              try {
                await FleetOpsService.assignVehicle(driverId, selectedVehicleId!);
                if (!mounted) return;
                Navigator.of(context).pop();
                _loadData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Management & Assignment'),
        actions: [
          ElevatedButton.icon(
            onPressed: _showAddDriverDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Driver'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _drivers.length,
              itemBuilder: (ctx, i) {
                final d = _drivers[i];
                final assigned = d['assignedVehicle'];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('${d['name']} (${d['licenseNumber']})'),
                    subtitle: Text('Phone: ${d['phone']} | Status: ${d['status']}'
                        '${assigned != null ? ' • Vehicle: ${assigned['vehicleNumber']}' : ''}'),
                    trailing: ElevatedButton(
                      onPressed: () => _showAssignDialog(d['id']),
                      child: const Text('Assign Vehicle'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
