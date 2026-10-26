import 'package:ami_admin/controllers/history_controller.dart';
import 'package:ami_admin/models/tokenHostory_model.dart';
import 'package:ami_admin/screens/payment_notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TokenHistoryScreen extends StatelessWidget {
  const TokenHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TokenHistoryController controller = Get.put(TokenHistoryController());
    final mealTypes = ['All', 'Breakfast', 'Lunch', 'Snacks', 'Dinner'];

    // Responsiveness variables
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 900;

    // ⚠️ First tap anywhere shows the payment notice; screen unlocks after "I understand".
    return PaymentNoticeGate(
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FE), // Softer background
        appBar: AppBar(
          toolbarHeight: 65,
          title: Text(
            "Generation Logs",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          backgroundColor: Color(0xffFFC800),
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ), // Dashboard width limit
            child: Column(
              children: [
                // --- ⚠️ PAYMENT / SERVER NOTICE ---
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: PaymentNoticeBanner(),
                ),

                // --- 📅 PROMINENT VISIBLE DATE & MEAL FILTER BAR ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: const Border(
                      bottom: BorderSide(color: Color(0xffE0E0E0), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Row 1: Visible Date Picker Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Filter Logs",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xffFFC800,
                              ).withValues(alpha: 0.15),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 16,
                              color: Colors.black87,
                            ),
                            label: Obx(
                              () => Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(controller.selectedDate.value),
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: controller.selectedDate.value,
                                firstDate: DateTime(2025),
                                lastDate: DateTime.now(),
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xffFFC800),
                                      onPrimary: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) controller.updateDate(picked);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Row 2: Meal Type Chips
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: mealTypes.map((meal) {
                                  return Obx(() {
                                    bool isSel =
                                        controller.selectedMealType.value ==
                                        meal;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(meal),
                                        selected: isSel,
                                        onSelected: (_) =>
                                            controller.changeMealType(meal),
                                        selectedColor: const Color(0xffFFC800),
                                        backgroundColor: const Color(
                                          0xffF8F9FA,
                                        ),
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: isSel
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSel
                                              ? Colors.black
                                              : Colors.grey[600],
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        side: BorderSide.none,
                                        showCheckmark: false,
                                      ),
                                    );
                                  });
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- 📋 LOGS GRID ---
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.historyList.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xffFFC800),
                        ),
                      );
                    }
                    if (controller.historyList.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No logs found for this selection",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      );
                    }

                    return GridView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth > 1200
                            ? 3
                            : (isWideScreen ? 2 : 1),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent:
                            100, // Compact height for cleaner dashboard
                      ),
                      itemCount: controller.historyList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == controller.historyList.length) {
                          return controller.isLoadingMore.value
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xffFFC800),
                                  ),
                                )
                              : const SizedBox(height: 40);
                        }
                        return _buildHistoryCard(controller.historyList[index]);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(TokenHistoryItem item) {
    return _HoverableCard(
      child: Row(
        children: [
          // Token Badge
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xffFFC800).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "#${item.tokenNumber}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.mealType.substring(0, 3).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Room ${item.room} • ${item.enrollmentNo}",
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Time
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('h:mm a').format(item.generatedAt.toLocal()),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('dd MMM').format(item.generatedAt.toLocal()),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper Widget for Web Hover Effect
class _HoverableCard extends StatefulWidget {
  final Widget child;
  const _HoverableCard({required this.child});

  @override
  State<_HoverableCard> createState() => __HoverableCardState();
}

class __HoverableCardState extends State<_HoverableCard> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isHovered ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}