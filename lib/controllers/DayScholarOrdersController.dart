import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DayScholarOrdersController extends GetxController {
  var isLoading = true.obs;
  var orders = <dynamic>[].obs;
  var stats = {}.obs;

  var selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now()).obs;
  var selectedMealType = 'All'.obs;
  var selectedGender = 'All'.obs;
  var selectedDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading(true);
      String urlStr =
          '${ApiEndpoints.adminDayScholarOrders}?month=${selectedMonth.value}&mealType=${selectedMealType.value}&gender=${selectedGender.value}';

      // Attach formatted date if selected
      if (selectedDate.value != null) {
        String formattedDate = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDate.value!);
        urlStr += '&date=$formattedDate';
      }

      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        orders.assignAll(data['orders']);
        stats.value = data['stats'];
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load day scholar orders");
    } finally {
      isLoading(false);
    }
  }

  void updateFilters({
    String? month,
    String? mealType,
    String? gender,
    DateTime? date,
    bool clearDate = false,
  }) {
    if (month != null) selectedMonth.value = month;
    if (mealType != null) selectedMealType.value = mealType;
    if (gender != null) selectedGender.value = gender;
    if (clearDate) {
      selectedDate.value = null;
    } else if (date != null) {
      selectedDate.value = date;
    }
    fetchOrders();
  }
}
