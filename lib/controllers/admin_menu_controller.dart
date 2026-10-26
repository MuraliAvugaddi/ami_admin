import 'package:ami_admin/services/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminMenuController extends GetxController {
  final MenuService _menuService = MenuService();

  var isLoading = false.obs;
  var selectedDay = 'Mon'.obs;

  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ✅ Defaults to the current month (no more hard-coded "August 2026")
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final monthController = TextEditingController(
    text: '${_monthNames[DateTime.now().month - 1]} ${DateTime.now().year}',
  );
  final yearController = TextEditingController(text: '${DateTime.now().year}');

  // Controllers map for each day and meal type
  final Map<String, Map<String, TextEditingController>> formControllers = {};

  @override
  void onInit() {
    super.onInit();
    for (var day in days) {
      formControllers[day] = {
        'breakfast': TextEditingController(),
        'lunch': TextEditingController(),
        'snacks': TextEditingController(),
        'dinner': TextEditingController(),
      };
    }
  }

  @override
  void onClose() {
    for (var day in days) {
      formControllers[day]!.values.forEach((controller) => controller.dispose());
    }
    monthController.dispose();
    yearController.dispose();
    super.onClose();
  }

  void changeDay(String day) {
    selectedDay.value = day;
  }

  // Helper function to turn comma-separated string into List<String>
  List<String> _parseCommaSeparatedItems(String text) {
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  // Submit full menu payload to backend
  Future<void> publishMenu() async {
    try {
      isLoading(true);

      Map<String, dynamic> weeklySchedule = {};
      for (var day in days) {
        weeklySchedule[day] = {
          'breakfast': _parseCommaSeparatedItems(formControllers[day]!['breakfast']!.text),
          'lunch': _parseCommaSeparatedItems(formControllers[day]!['lunch']!.text),
          'snacks': _parseCommaSeparatedItems(formControllers[day]!['snacks']!.text),
          'dinner': _parseCommaSeparatedItems(formControllers[day]!['dinner']!.text),
        };
      }

      final payload = {
        'month': monthController.text.trim(),
        'year': int.tryParse(yearController.text.trim()) ?? 2026,
        'weeklySchedule': weeklySchedule,
      };

      bool isPublished = await _menuService.uploadMonthlyMenu(payload);

      if (isPublished) {
        Get.snackbar(
          'Success',
          'Monthly mess menu published successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Upload Failed',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }
}