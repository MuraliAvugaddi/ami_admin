import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ami_admin/models/tokenHostory_model.dart';
import 'package:ami_admin/apis/apis_localhost.dart';

class TokenHistoryController extends GetxController {
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var historyList = <TokenHistoryItem>[].obs;

  var selectedMealType = 'All'.obs;
  var selectedDate = DateTime.now().obs;

  int currentPage = 1;
  int totalPages = 1;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchHistory(isRefresh: true);
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      if (currentPage < totalPages && !isLoadingMore.value) {
        loadMoreHistory();
      }
    }
  }

  void updateDate(DateTime pickedDate) {
    selectedDate.value = pickedDate;
    fetchHistory(isRefresh: true);
  }

  void changeMealType(String mealType) {
    selectedMealType.value = mealType;
    fetchHistory(isRefresh: true);
  }

  Future<void> fetchHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      historyList.clear();
      isLoading(true);
    }

    try {
      String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate.value);
      String url =
          "${ApiEndpoints.adminBase}/history?page=$currentPage&limit=20&date=$formattedDate";

      if (selectedMealType.value != 'All') {
        url += "&mealType=${selectedMealType.value}";
      }

      print("🌐 Fetching URL: $url"); // Debug print

      final response = await http.get(Uri.parse(url));
      print("📥 Response Status: ${response.statusCode}"); // Debug print
      print("📥 Response Body: ${response.body}"); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        totalPages = data['totalPages'] ?? 1;
        List<dynamic> historyData = data['history'] ?? [];

        var fetchedItems = historyData
            .map((x) => TokenHistoryItem.fromJson(x))
            .toList();
        if (isRefresh) {
          historyList.assignAll(fetchedItems);
        } else {
          historyList.addAll(fetchedItems);
        }
      } else {
        throw Exception("Server returned code ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error in fetchHistory: $e"); // Debug print
      Get.snackbar("Error", "Failed to fetch token history");
    } finally {
      isLoading(false);
      isLoadingMore(false);
    }
  }

  Future<void> loadMoreHistory() async {
    if (currentPage >= totalPages) return;
    currentPage++;
    isLoadingMore(true);
    try {
      String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate.value);
      String url =
          "${ApiEndpoints.adminBase}/history?page=$currentPage&limit=20&date=$formattedDate";

      if (selectedMealType.value != 'All') {
        url += "&mealType=${selectedMealType.value}";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> historyData = data['history'] ?? [];
        var fetchedItems = historyData
            .map((x) => TokenHistoryItem.fromJson(x))
            .toList();
        historyList.addAll(fetchedItems);
      }
    } catch (e) {
      currentPage--;
    } finally {
      isLoadingMore(false);
    }
  }
}
