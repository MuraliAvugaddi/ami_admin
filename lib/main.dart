import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/hostel_session.dart';
import 'package:ami_admin/screens/login_screen.dart';
import 'package:ami_admin/services/Api_token_history.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
// Import Flutter and GetX
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  // Ensure that Flutter bindings are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  Get.put<ApiService>(ApiService());
  // -------------------------

  // Hostel staff stay logged in (director / warden / attender / repair team)
  await GetStorage.init();
  HostelStaffService.onSessionExpired = () => HostelSession.logout(expired: true);
  if (StaffSession.isLoggedIn) {
    Get.put(HostelStaffController(), permanent: true);
  }

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use GetMaterialApp as you are using GetX for state management.
    return GetMaterialApp(
      title: 'Ami Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal, // Changed color for better UI consistency
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(
            0xffFFC800,
          ), // Keeping your brand color for AppBar
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
      ),
      // The app now starts directly at the HomeScreen.
      home: StaffSession.isLoggedIn ? HostelSession.homeFor(StaffSession.role) : LoginScreen(),
    );
  }
}
