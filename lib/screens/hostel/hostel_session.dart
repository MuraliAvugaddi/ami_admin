import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/hostel_home_screen.dart';
import 'package:ami_admin/screens/hostel/worker_jobs_screen.dart';
import 'package:ami_admin/screens/login_screen.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// HOSTEL SESSION — open the right home after login, logout
// ============================================================

class HostelSession {
  /// Home screen for the logged-in hostel staff
  static Widget homeFor(String role) => role == 'worker' ? const WorkerJobsScreen() : const HostelHomeScreen();

  /// Start live updates + open home
  static void start() {
    if (!Get.isRegistered<HostelStaffController>()) {
      Get.put(HostelStaffController(), permanent: true);
    }
    Get.offAll(() => homeFor(StaffSession.role));
  }

  static bool _loggingOut = false;

  static Future<void> logout({bool expired = false}) async {
    if (_loggingOut) return;
    _loggingOut = true;
    if (Get.isRegistered<HostelStaffController>()) {
      Get.find<HostelStaffController>().disconnect();
      await Get.delete<HostelStaffController>(force: true);
    }
    await StaffSession.clear();
    _loggingOut = false;
    Get.offAll(() => const LoginScreen());
    if (expired) {
      Get.snackbar(
        'Session ended',
        'Please login again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  static Future<void> confirmLogout() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'You will stop getting SOS alarms on this phone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await logout();
  }
}
