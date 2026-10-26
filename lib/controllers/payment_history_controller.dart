import 'package:ami_admin/services/updateing_user_status_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentHistoryController extends GetxController {
  var isLoading = true.obs;
  var payments = <dynamic>[].obs;

  var selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now()).obs;
  var selectedGender = 'All'.obs;
  var selectedDate = Rxn<DateTime>();
  var searchQuery = ''.obs;

  List<dynamic> get filteredPayments {
    if (searchQuery.value.isEmpty) return payments;
    String q = searchQuery.value.toLowerCase().trim();
    return payments.where((p) {
      if (p is! Map) return false;
      
      // Safely access user map even if userId is just an unpopulated string ID
      final user = (p['userId'] is Map) ? (p['userId'] as Map) : {};
      
      String name = (user['name'] ?? '').toString().toLowerCase();
      String enrollment = (user['enrollmentNo'] ?? '').toString().toLowerCase();
      String phone = (user['phonenumber'] ?? '').toString().toLowerCase();
      String txnId = (p['transactionId'] ?? '').toString().toLowerCase();
      
      return name.contains(q) ||
          enrollment.contains(q) ||
          phone.contains(q) ||
          txnId.contains(q);
    }).toList();
  }

  int get totalStudentsPaid => filteredPayments.length;
  int get onlineCount =>
      filteredPayments.where((p) => p is Map && p['method'] != 'offline').length;
  int get cashCount =>
      filteredPayments.where((p) => p is Map && p['method'] == 'offline').length;

  double get totalCollection => filteredPayments.fold(0.0, (sum, item) {
        if (item is! Map) return sum;
        final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        return sum + amt;
      });

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    try {
      isLoading(true);
      final data = await AdminService.fetchGlobalPayments(
        selectedMonth.value,
        selectedGender.value,
        date: selectedDate.value,
      );
      payments.assignAll(data);
    } catch (e) {
      Get.snackbar(
        "Sync Error",
        "Failed to sync payment records",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateFilters({
    String? month,
    String? gender,
    DateTime? date,
    bool clearDate = false,
  }) {
    if (month != null) selectedMonth.value = month;
    if (gender != null) selectedGender.value = gender;
    if (clearDate) {
      selectedDate.value = null;
    } else if (date != null) {
      selectedDate.value = date;
    }
    fetchPayments();
  }
}