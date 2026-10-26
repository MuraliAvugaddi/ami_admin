import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/updateing_user_status_service.dart';

class SkipReportController extends GetxController {
  var isLoading = true.obs;
  var skipList = <dynamic>[].obs;

  var selectedDate = DateTime.now().add(const Duration(days: 1)).obs;
  var selectedMealType = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSkipReport();
  }

  // ✅ NEW: Helper methods to calculate counts for the UI breakdown
  int getCount(String type) => skipList.where((item) => item['mealType'] == type).length;
  int get totalSkips => skipList.length;

  Future<void> fetchSkipReport() async {
    try {
      isLoading(true);
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      
      final data = await AdminService.getSkipReport(formattedDate, selectedMealType.value);
      skipList.assignAll(data);
    } catch (e) {
      Get.snackbar("Error", "Could not load skip reports");
    } finally {
      isLoading(false);
    }
  }

  void updateFilters(DateTime date, String meal) {
    selectedDate.value = date;
    selectedMealType.value = meal;
    fetchSkipReport();
  }
}