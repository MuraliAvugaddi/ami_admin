import 'package:ami_admin/screens/homeScreen.dart';
import 'package:ami_admin/screens/hostel/hostel_session.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoading = false.obs; // ✅ Reactive loading state

  final HostelStaffService _staffService = HostelStaffService();

  void login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Input Required', 'Please fill in both fields', 
        backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    
    // Simulate a small network delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    // --- Mess admin (old fixed login, still works) ---
    if (email == '123321' && password == '321123') {
      _openMessDashboard();
      isLoading.value = false;
      return;
    }

    // --- Staff login: mess admin / director / warden / attender / repair team ---
    final res = await _staffService.login(email, password);
    isLoading.value = false;

    if (res['success'] != true || res['token'] == null) {
      Get.snackbar('Access Denied', '${res['message'] ?? 'Invalid credentials.'}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    final staff = Map<String, dynamic>.from(res['staff'] as Map);

    if (staff['role'] == 'mess_admin') {
      _openMessDashboard();
      return;
    }

    await StaffSession.save('${res['token']}', staff);
    Get.snackbar('Welcome', '${staff['name']} • ${StaffSession.roleName('${staff['role']}')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white);
    HostelSession.start();
  }

  void _openMessDashboard() {
    Get.snackbar('Success', 'Welcome back, Admin!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white);
    Get.offAll(() =>  Homescreen());
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
