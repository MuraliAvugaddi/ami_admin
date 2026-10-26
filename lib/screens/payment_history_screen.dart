import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/payment_history_controller.dart';

class GlobalPaymentHistoryScreen extends StatelessWidget {
  const GlobalPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentHistoryController());
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FE),
      appBar: AppBar(
        title: Text(
          "Revenue Records",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xffFFC800),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Branded Executive Summary Banner & Filter/Search Section
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    _buildExecutiveSummaryCard(controller),
                    _buildFilterBar(context, controller),
                    _buildSearchBar(controller),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Content List
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xffFFC800)),
                ),
              );
            }

            final displayList = controller.filteredPayments;

            if (displayList.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No payment records found for this selection",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? (screenWidth - 1000) / 2 : 16,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final payment = displayList[index];

                  // Safe extraction preventing String index error
                  final Map<dynamic, dynamic> user = (payment is Map && payment['userId'] is Map)
                      ? (payment['userId'] as Map)
                      : {};

                  final bool isOffline = payment['method'] == 'offline';

                  DateTime paidAt;
                  try {
                    paidAt = DateTime.parse(payment['paidAt'].toString()).toLocal();
                  } catch (_) {
                    paidAt = DateTime.now();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xffFFC800).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isOffline
                                  ? Icons.payments_outlined
                                  : Icons.account_balance_wallet_outlined,
                              color: Colors.black87,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user['name']?.toString() ?? "Unknown Student",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOffline
                                            ? Colors.orange.shade100
                                            : const Color(0xffFFC800).withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isOffline ? "CASH" : "ONLINE",
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: isOffline
                                              ? Colors.orange.shade800
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // --- STUDENT DETAILS ---
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 2,
                                  children: [
                                    _metaInfo(
                                      Icons.badge_outlined,
                                      "ID: ${user['enrollmentNo'] ?? 'N/A'}",
                                    ),
                                    _metaInfo(
                                      Icons.school_outlined,
                                      "Year: ${user['year'] ?? 'N/A'}",
                                    ),
                                    _metaInfo(
                                      Icons.meeting_room_outlined,
                                      "Room: ${user['room'] ?? 'N/A'}",
                                    ),
                                    _metaInfo(
                                      Icons.phone_outlined,
                                      "${user['phonenumber'] ?? 'N/A'}",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // --- TRANSACTION ID & TIMESTAMP ---
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      "Txn: ${payment['transactionId'] ?? 'Manual Cash Entry'}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM, hh:mm a').format(paidAt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹${payment['amount'] ?? 0}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: displayList.length),
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // --- BRANDED EXECUTIVE SUMMARY CARD ---
  Widget _buildExecutiveSummaryCard(PaymentHistoryController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1E1E1E), Color(0xff2D2D2D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Collection",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFC800).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xffFFC800),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Obx(
              () => Text(
                "₹${controller.totalCollection.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  color: const Color(0xffFFC800),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            // --- METRICS BREAKDOWN ---
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statBadge(
                    "Total Paid",
                    "${controller.totalStudentsPaid} Students",
                    const Color(0xffFFC800),
                  ),
                  _statBadge(
                    "Online Payments",
                    "${controller.onlineCount}",
                    Colors.white,
                  ),
                  _statBadge(
                    "Cash Entries",
                    "${controller.cashCount}",
                    Colors.orangeAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _metaInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: const Color(0xffFFC800),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    PaymentHistoryController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _filterTile(
              value: controller.selectedGender,
              icon: Icons.person_search_outlined,
              onTap: () => _showPicker(
                context,
                "Select Gender",
                ["All", "Male", "Female"],
                (val) => controller.updateFilters(gender: val),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              icon: const Icon(
                Icons.calendar_month,
                size: 16,
                color: Color(0xffFFC800),
              ),
              label: Obx(
                () => Text(
                  controller.selectedDate.value == null
                      ? "Filter Date"
                      : DateFormat(
                          'dd MMM yyyy',
                        ).format(controller.selectedDate.value!),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate.value ?? DateTime.now(),
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  controller.updateFilters(date: pickedDate);
                }
              },
            ),
          ),
          Obx(
            () => controller.selectedDate.value != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () =>
                          controller.updateFilters(clearDate: true),
                      tooltip: "Clear Date Filter",
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(PaymentHistoryController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: TextField(
          onChanged: controller.updateSearchQuery,
          decoration: InputDecoration(
            hintText: "Search by student name, ID, phone, or transaction ID...",
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xffFFC800),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _filterTile({
    required RxString value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xffFFC800)),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => Text(
                  value.value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    String title,
    List<String> options,
    Function(String) onSelect,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map(
              (option) => ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(option, style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  onSelect(option);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
