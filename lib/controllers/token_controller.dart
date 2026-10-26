import 'package:ami_admin/services/token_status_service.dart';
import 'package:get/get.dart';

class TokenStatsController extends GetxController {
  final TokenStatsService _apiService = TokenStatsService();

  var isLoading = true.obs;

  var errorMessage = ''.obs;
  final RxMap<String, int> todayStats = <String, int>{}.obs;
  final RxMap<String, int> yesterdayStats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading(true);
      errorMessage('');

      final DateTime today = DateTime.now();
      final DateTime yesterday = today.subtract(const Duration(days: 1));

      final results = await Future.wait([
        _apiService.getStatsForDate(today),
        _apiService.getStatsForDate(yesterday),
      ]);

      todayStats.value = results[0];
      yesterdayStats.value = results[1];
    } catch (e) {
      errorMessage('Failed to fetch data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }
}
