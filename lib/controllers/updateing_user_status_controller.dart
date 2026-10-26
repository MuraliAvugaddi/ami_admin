import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../apis/apis_localhost.dart';
import '../models/user_models.dart';

class AdminController extends GetxController {
  var usersList = <AppUser>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase().trim();
  }

  List<AppUser> get filteredUsers {
    if (searchQuery.value.isEmpty) {
      return usersList;
    }
    final q = searchQuery.value;
    return usersList.where((u) {
      final name = u.name.toLowerCase();
      final phone = u.phonenumber.toLowerCase();
      final enrollment = u.enrollmentNo.toLowerCase();
      final room = u.room.toLowerCase();
      return name.contains(q) ||
          phone.contains(q) ||
          enrollment.contains(q) ||
          room.contains(q);
    }).toList();
  }

  // Uses hasValidAccess to accurately separate active vs expired students
  List<AppUser> get activeUsers =>
      filteredUsers.where((u) => u.hasValidAccess).toList();

  List<AppUser> get expiredUsers =>
      filteredUsers.where((u) => !u.hasValidAccess).toList();

  int get totalUsersCount => usersList.length;
  int get totalActiveCount => usersList.where((u) => u.hasValidAccess).length;
  int get totalInactiveCount => usersList.where((u) => !u.hasValidAccess).length;

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(ApiEndpoints.adminUsers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        usersList.assignAll(data.map((item) => AppUser.fromJson(item)).toList());
      } else {
        Get.snackbar("Sync Warning", "Could not fetch students (${response.statusCode})");
      }
    } catch (e) {
      Get.snackbar("Network Issue", "Failed to connect to backend server: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleApproval(AppUser user) async {
    final cleanId = user.id.trim();
    if (cleanId.isEmpty || cleanId == 'N/A') {
      Get.snackbar("Invalid Account", "This student record lacks a valid ID.");
      return;
    }

    final originalStatus = user.hasValidAccess;
    final newStatus = !originalStatus;

    // Optimistic UI update
    user.isApproved.value = newStatus;
    usersList.refresh();

    try {
      final patchUrl = Uri.parse("${ApiEndpoints.adminUsers}/$cleanId/status");
      var response = await http.patch(
        patchUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}',
        },
        body: jsonEncode({'isApproved': newStatus}),
      );

      if (response.statusCode != 200) {
        final putUrl = Uri.parse("${ApiEndpoints.adminUsers}/$cleanId/status");
        response = await http.put(
          putUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}',
          },
          body: jsonEncode({'isApproved': newStatus}),
        );
      }

      if (response.statusCode == 200) {
        Get.snackbar(
          "Status Updated",
          "${user.name} is now ${newStatus ? 'ACTIVE' : 'DEACTIVATED'}.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        user.isApproved.value = originalStatus;
        usersList.refresh();
        Get.snackbar(
          "Update Failed",
          "Server returned status code: ${response.statusCode}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      user.isApproved.value = originalStatus;
      usersList.refresh();
      Get.snackbar(
        "Connection Error",
        "Could not contact server: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showDeactivateAllDialog(BuildContext context) {
    Get.defaultDialog(
      title: "Reset Month Access",
      middleText: "Are you sure you want to deactivate mess access for ALL students?",
      textConfirm: "Deactivate All",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await deactivateAll();
      },
    );
  }

  Future<void> deactivateAll() async {
    try {
      isLoading.value = true;
      final response = await http.patch(
        Uri.parse("${ApiEndpoints.adminUsers}/deactivate-all"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}',
        },
      );

      if (response.statusCode == 200) {
        for (var u in usersList) {
          u.isApproved.value = false;
        }
        usersList.refresh();
        Get.snackbar(
          "Access Cleared",
          "All students set to inactive for the new cycle.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("Error", "Failed to reset student access.");
      }
    } catch (e) {
      Get.snackbar("Error", "Network error during reset: $e");
    } finally {
      isLoading.value = false;
    }
  }
}