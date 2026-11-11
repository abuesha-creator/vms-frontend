import 'package:flutter/material.dart';
import '../services/fleet_ops_service.dart';

class FleetOperationsScreen extends StatefulWidget {
  const FleetOperationsScreen({super.key});

  @override
  State<FleetOperationsScreen> createState() => _FleetOperationsScreenState();
}

class _FleetOperationsScreenState extends State<FleetOperationsScreen> {
  Map<String, dynamic> _summary = {};
  List<dynamic> _vehicles = [];
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  int _page = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _loading = true);
    try {
      final sum = await FleetOpsService.getDashboardSummary();
      final paged = await FleetOpsService.getPagedVehicles(
        search: _searchQuery,
        status: _statusFilter,
        page: _page,
      );
      setState(() {
        _summary = sum;
        _vehicles = paged['content'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _openVehicleOpsSheet(Map<String, dynamic> vehicle) async {
    final vId = vehicle['id'];
    final docs = await FleetOpsService.getDocuments(vId);
    final maint = await FleetOpsService.getMaintenance(vId);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${vehicle['vehicleNumber']} - Documents & Maintenance'),
        content: SizedBox(
          width: 550,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Documents & Expiry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddDocDialog(vId);
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Add Document'),
                    ),
                  ],
                ),
                if (docs.isEmpty) const Text('No documents uploaded.'),
                ...docs.map((d) {
                  final expired = d['expired'] == true;
                  return ListTile(
                    dense: true,
                    title: Text(d['documentType'] ?? ''),
                    subtitle: Text('Expiry: ${d['expiryDate']}'),
                    trailing: Chip(
                      label: Text(expired ? 'EXPIRED' : 'VALID', style: const TextStyle(color: Colors.white)),
                      backgroundColor: expired ? Colors.red : Colors.green,
                    ),
                  );
                }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Maintenance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddMaintDialog(vId);
                      },
                      icon: const Icon(Icons.build),
                      label: const Text('Add Service'),
                    ),
                  ],
                ),
                if (maint.isEmpty) const Text('No maintenance history.'),
                ...maint.map((m) => ListTile(
                      dense: true,
                      title: Text('${m['serviceType']} - \$${m['cost']}'),
                      subtitle: Text('Date: ${m['serviceDate']} | Workshop: ${m['workshopName'] ?? 'N/A'}'),
                    )),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showAddDocDialog(int vehicleId) {
    final typeCtrl = TextEditingController(text: 'Registration');
    final dateCtrl = TextEditingController(text: '2026-12-31');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Document Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Document Type (e.g. Insurance)')),
            const SizedBox(height: 8),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FleetOpsService.addDocumentRecord(vehicleId, typeCtrl.text, dateCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              _refreshAll();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddMaintDialog(int vehicleId) {
    final typeCtrl = TextEditingController(text: 'Engine Oil Change');
    final costCtrl = TextEditingController(text: '120');
    final shopCtrl = TextEditingController(text: 'Stark Auto Care');
    final dateCtrl = TextEditingController(text: '2026-11-12');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Maintenance Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Service Type')),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Cost')),
            TextField(controller: shopCtrl, decoration: const InputDecoration(labelText: 'Workshop Name')),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FleetOpsService.addMaintenance(vehicleId, {
                'serviceType': typeCtrl.text,
                'cost': double.tryParse(costCtrl.text) ?? 0,
                'workshopName': shopCtrl.text,
                'serviceDate': dateCtrl.text,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _refreshAll();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Operations, Search & Summary')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statBadge('Total Vehicles', '${_summary['totalVehicles'] ?? 0}', Colors.blue),
                      _statBadge('Active', '${_summary['activeVehicles'] ?? 0}', Colors.green),
                      _statBadge('Maintenance', '${_summary['maintenanceVehicles'] ?? 0}', Colors.orange),
                      _statBadge('Drivers', '${_summary['totalDrivers'] ?? 0}', Colors.purple),
                      _statBadge('Expired Docs', '${_summary['expiredDocuments'] ?? 0}', Colors.red),
                      _statBadge('Maint. Cost', '\$${_summary['totalMaintenanceCost'] ?? 0}', Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search vehicle number, brand, company...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            _searchQuery = val;
                            _page = 0;
                            _refreshAll();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _statusFilter,
                        items: ['ALL', 'ACTIVE', 'INACTIVE', 'MAINTENANCE']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _statusFilter = val);
                            _refreshAll();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (ctx, i) {
                        final v = _vehicles[i];
                        return Card(
                          child: ListTile(
                            title: Text('${v['vehicleNumber']} - ${v['brand']} ${v['model']}'),
                            subtitle: Text('Company: ${v['company']} | Status: ${v['status']}'),
                            trailing: ElevatedButton.icon(
                              onPressed: () => _openVehicleOpsSheet(v),
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Docs & Maintenance'),
),
),
);
},
),
),
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
TextButton(
onPressed: _page > 0 ? () { setState(() => _page--); _refreshAll(); } : null,
child: const Text('Previous Page'),
),
Text('Page ${_page + 1}'),
TextButton(
onPressed: _vehicles.length >= 10 ? () { setState(() => _page++); _refreshAll(); } : null,
child: const Text('Next Page'),
),
],
),
],
),
),
);
}
Widget _statBadge(String label, String value, Color color) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.1),
borderRadius: BorderRadius.circular(8),
border: Border.all(color: color),
),
child: Column(
children: [
Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
Text(label, style: const TextStyle(fontSize: 12)),
],
),
);
}
}