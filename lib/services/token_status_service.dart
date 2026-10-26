import 'dart:convert';
import 'package:ami_admin/apis/api_endpoints.dart';
import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TokenStatsService {
  Future<Map<String, int>> getStatsForDate(DateTime date) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final Uri url = Uri.parse('${ApiEndpoints.tokenStats}?date=$formattedDate');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data.map((key, value) => MapEntry(key, (value ?? 0) as int));
      }
      throw Exception('Error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error');
    }
  }
}
