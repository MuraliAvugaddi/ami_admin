import 'dart:convert';
import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:http/http.dart' as http;

class MenuService {
  // Fetch active menu
  Future<Map<String, dynamic>> fetchActiveMenu() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.menuActive),
        headers: {'Content-Type': 'application/json'},
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Invalid response from server (${response.statusCode}). Check backend URL.',
        );
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return data['menu'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load active menu.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Upload / Publish New Monthly Menu
  Future<bool> uploadMonthlyMenu(Map<String, dynamic> menuPayload) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.adminUploadMenu),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(menuPayload),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Server returned HTTP ${response.statusCode}. Route not found or server error.',
        );
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to publish menu.');
      }
    } catch (e) {
      rethrow;
    }
  }
}