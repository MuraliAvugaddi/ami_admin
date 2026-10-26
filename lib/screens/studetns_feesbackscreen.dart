import 'dart:convert';
import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:ami_admin/screens/payment_notice_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class StudentsFeedbackScreen extends StatefulWidget {
  const StudentsFeedbackScreen({super.key});

  @override
  State<StudentsFeedbackScreen> createState() => _StudentsFeedbackScreenState();
}

class _StudentsFeedbackScreenState extends State<StudentsFeedbackScreen> {
  var isLoading = true.obs;
  var feedbackList = <dynamic>[].obs;
  var errorMessage = ''.obs;

  DateTime? selectedDate;

  // Theme Colors matching your reference screenshot
  static const Color brandYellow = Color(0xFFFFC800);
  static const Color brandDarkCard = Color(0xFF212121);
  static const Color brandDarkText = Color(0xFF252A27);
  static const Color brandLightText = Color(0xFF7C837F);
  static const Color backgroundCol = Color(0xFFF4F5F7);

  @override
  void initState() {
    super.initState();
    fetchFeedback();
  }

  Future<void> fetchFeedback() async {
    try {
      isLoading(true);
      errorMessage('');
      final box = GetStorage();
      final token = box.read('token');

      String url = ApiEndpoints.adminFeedbackList;
      if (selectedDate != null) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
        url += "?date=$formattedDate";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        feedbackList.value = jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load feedback records (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading(false);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: brandYellow,
              onPrimary: brandDarkText,
              surface: Colors.white,
              onSurface: brandDarkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      fetchFeedback();
    }
  }

  double get _averageRating {
    if (feedbackList.isEmpty) return 0.0;
    double sum = feedbackList.fold(
      0,
      (prev, element) => prev + (element['rating'] ?? 0),
    );
    return sum / feedbackList.length;
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ First tap anywhere shows the payment notice; screen unlocks after "I understand".
    return PaymentNoticeGate(
      child: Scaffold(
      backgroundColor: backgroundCol,
      appBar: AppBar(
        title: Text(
          selectedDate == null
              ? "Student Feedback"
              : "Feedback: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
          style: const TextStyle(
            color: brandDarkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: brandYellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: brandDarkText),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: brandDarkText,
            ),
            tooltip: "Filter by Date",
            onPressed: () => _pickDate(context),
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: brandDarkText),
              tooltip: "Clear Filter",
              onPressed: () {
                setState(() {
                  selectedDate = null;
                });
                fetchFeedback();
              },
            ),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: brandYellow),
          );
        }

        if (errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: brandYellow,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: brandLightText),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandYellow,
                      foregroundColor: brandDarkText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Retry",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Responsive Web & Mobile Wrapper Container
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 850 : double.infinity,
            ),
            child: Column(
              children: [
                // --- ⚠️ PAYMENT / SERVER NOTICE ---
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: PaymentNoticeBanner(),
                ),

                // Dark Summary Banner Card (Matched from Revenue Records Style)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: brandDarkCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Feedbacks Received",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.forum_rounded,
                              color: brandYellow,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${feedbackList.length}",
                        style: const TextStyle(
                          color: brandYellow,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(color: Colors.white12, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Average Rating",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: brandYellow,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Filter Status",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedDate == null
                                    ? "All Time"
                                    : DateFormat(
                                        'dd MMM',
                                      ).format(selectedDate!),
                                style: const TextStyle(
                                  color: brandYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Feedback List Section
                Expanded(
                  child: feedbackList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: brandLightText.withOpacity(0.4),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "No feedback records found.",
                                style: TextStyle(
                                  color: brandLightText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: brandYellow,
                          onRefresh: fetchFeedback,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: feedbackList.length,
                            itemBuilder: (context, index) {
                              final item = feedbackList[index];
                              final user = item['user'] ?? {};
                              final int rating = item['rating'] ?? 5;
                              final String message = item['message'] ?? '';
                              final String dateStr = item['createdAt'] != null
                                  ? DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(DateTime.parse(item['createdAt']))
                                  : '';

                              final String name =
                                  user['name'] ?? 'Unknown Student';
                              final String enrollment =
                                  user['enrollmentNo'] ?? 'N/A';
                              final String phone = user['phonenumber'] ?? 'N/A';
                              final String room =
                                  user['room']?.toString() ?? 'N/A';
                              final String course = user['course'] ?? 'N/A';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEFEFEA),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header Row: Icon, Name & Stars
                                      Row(
                                        children: [
                                          Container(
                                            height: 38,
                                            width: 38,
                                            decoration: BoxDecoration(
                                              color: brandYellow.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.person_outline_rounded,
                                              color: brandDarkText,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: brandDarkText,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(
                                                    color: brandLightText,
                                                    fontSize: 10.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (starIdx) => Icon(
                                                starIdx < rating
                                                    ? Icons.star_rounded
                                                    : Icons
                                                          .star_outline_rounded,
                                                color: brandYellow,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Student Details Chips
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 5,
                                        children: [
                                          _buildInfoBadge(
                                            Icons.badge_outlined,
                                            "ID: $enrollment",
                                          ),
                                          _buildInfoBadge(
                                            Icons.meeting_room_outlined,
                                            "Room: $room",
                                          ),
                                          _buildInfoBadge(
                                            Icons.school_outlined,
                                            "Course: $course",
                                          ),
                                          _buildInfoBadge(
                                            Icons.phone_outlined,
                                            phone,
                                          ),
                                        ],
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Divider(
                                          height: 1,
                                          color: Color(0xFFF2F2EF),
                                        ),
                                      ),

                                      // Feedback message box
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(11),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAF9F6),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFEFEFEA),
                                          ),
                                        ),
                                        child: Text(
                                          message.isEmpty
                                              ? "No remarks written."
                                              : message,
                                          style: TextStyle(
                                            color: message.isEmpty
                                                ? brandLightText
                                                : brandDarkText,
                                            fontSize: 13,
                                            height: 1.35,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: message.isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      }),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEBEBE5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: brandLightText),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: brandDarkText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}