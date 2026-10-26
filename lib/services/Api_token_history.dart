import 'package:ami_admin/apis/api_endpoints.dart';
import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:ami_admin/models/tokenHostory_model.dart';
import 'package:get/get.dart';

class ApiService extends GetConnect {
  Future<List<TokenHistoryItem>> fetchTokenHistory(
    int page,
    String mealType, {
    String? date,
  }) async {
    try {
      String url = '${ApiEndpoints.adminHistory}?page=$page&limit=20&mealType=$mealType';
      if (date != null) url += '&date=$date';

      final response = await get(
        url,
        headers: {'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> historyJson = response.body['history'];
        return historyJson.map((json) => TokenHistoryItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}