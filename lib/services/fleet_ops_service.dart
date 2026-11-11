import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class FleetOpsService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/v1';

  static Map<String, String> _getHeaders({bool isJson = true}) {
    final headers = <String, String>{
      ...AuthService().authHeaders,
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  // ১. ড্যাশবোর্ড সামারি (Dashboard Summary)
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/summary'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    }
    throw Exception('Failed to load dashboard summary');
  }

  // ২. সার্চ ও ফিল্টারসহ গাড়ির তালিকা (Search, Filter & Pagination)
  static Future<Map<String, dynamic>> getPagedVehicles({
    String search = '',
    String status = '',
    int page = 0,
    int size = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/vehicles/paged').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (status.isNotEmpty && status != 'ALL') 'status': status,
      'page': page.toString(),
      'size': size.toString(),
    });
    final response = await http.get(uri, headers: _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    }
    throw Exception('Failed to fetch paged vehicles');
  }

  // ৩. ড্রাইভার ম্যানেজমেন্ট ও অ্যাসাইনমেন্ট (Drivers & Assignment)
  static Future<List<dynamic>> getDrivers() async {
    final response = await http.get(Uri.parse('$_baseUrl/drivers'), headers: _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception('Failed to load drivers');
  }

  static Future<void> createDriver(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/drivers'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to add driver');
  }

  static Future<void> assignVehicle(int driverId, int vehicleId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/drivers/$driverId/assign/$vehicleId'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)['message'] ?? 'Assignment failed');
  }

  // ৪. ডকুমেন্ট ও মেইনটেন্যান্স (Documents & Maintenance)
  static Future<List<dynamic>> getDocuments(int vehicleId) async {
    final response = await http.get(Uri.parse('$_baseUrl/vehicles/$vehicleId/documents'), headers: _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception('Failed to load documents');
  }

  static Future<void> addDocumentRecord(int vehicleId, String type, String expiryDate) async {
    final uri = Uri.parse('$_baseUrl/vehicles/$vehicleId/documents').replace(queryParameters: {
      'documentType': type,
      'expiryDate': expiryDate,
    });
    final response = await http.post(uri, headers: _getHeaders(isJson: false));
    if (response.statusCode != 201) throw Exception('Failed to save document');
  }

  static Future<List<dynamic>> getMaintenance(int vehicleId) async {
    final response = await http.get(Uri.parse('$_baseUrl/vehicles/$vehicleId/maintenance'), headers: _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception('Failed to load maintenance');
  }

  static Future<void> addMaintenance(int vehicleId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/vehicles/$vehicleId/maintenance'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) throw Exception('Failed to add maintenance');
  }
}
