import 'package:ami_admin/controllers/admin_menu_controller.dart';
import 'package:ami_admin/screens/payment_notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFFFADD73);
const Color primaryDark = Color(0xFFD5A514);
const Color darkTextColor = Color(0xFF252A27);

class AdminMenuUploadScreen extends StatelessWidget {
  const AdminMenuUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminMenuController controller = Get.put(AdminMenuController());
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 850;

    // ⚠️ First tap anywhere shows the payment notice; screen unlocks after "I understand".
    return PaymentNoticeGate(
      child: Scaffold(
      backgroundColor: const Color(0xffF4F7FE),
      appBar: AppBar(
        title: Text(
          "Publish Mess Menu",
          style: GoogleFonts.poppins(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xffFFC800),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTextColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ⚠️ PAYMENT / SERVER NOTICE ---
                  const PaymentNoticeBanner(),

                  // --- 📅 MONTH & YEAR INPUT CONTAINER ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Schedule Period",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: darkTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: controller.monthController,
                                decoration: InputDecoration(
                                  labelText: "Month Name",
                                  hintText: "e.g. September 2026",
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: controller.yearController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Year",
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 🗓️ DAY SELECTOR CHIPS ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: primaryDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Select Day to Edit Items",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: darkTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tip: Separate individual menu items with commas.",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: controller.days.map((day) {
                              bool isSelected =
                                  controller.selectedDay.value == day;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(day),
                                  selected: isSelected,
                                  selectedColor: primaryDark,
                                  backgroundColor: const Color(0xffF8F9FA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : darkTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (_) => controller.changeDay(day),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 🍳 MEAL INPUT FIELDS CONTAINER ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
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
                            Text(
                              "Menu for: ${controller.selectedDay.value}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: darkTextColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Editing",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: darkTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Responsive Layout for Inputs (2 columns on wide screens, stacked on mobile)
                        if (isWideScreen) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  "Breakfast Items",
                                  controller.formControllers[controller
                                      .selectedDay
                                      .value]!['breakfast']!,
                                  "e.g. Idli Sambar, Chutney, Tea",
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  "Lunch Items",
                                  controller.formControllers[controller
                                      .selectedDay
                                      .value]!['lunch']!,
                                  "e.g. Chole, Dal, Pulao, Roti",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  "Snacks Items",
                                  controller.formControllers[controller
                                      .selectedDay
                                      .value]!['snacks']!,
                                  "e.g. Pani Puri, Tea",
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  "Dinner Items",
                                  controller.formControllers[controller
                                      .selectedDay
                                      .value]!['dinner']!,
                                  "e.g. Soya Chilli, Dal Fry, Jalebi",
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildInputField(
                            "Breakfast Items",
                            controller.formControllers[controller
                                .selectedDay
                                .value]!['breakfast']!,
                            "e.g. Idli Sambar, Chutney, Tea",
                          ),
                          const SizedBox(height: 14),
                          _buildInputField(
                            "Lunch Items",
                            controller.formControllers[controller
                                .selectedDay
                                .value]!['lunch']!,
                            "e.g. Chole, Dal, Pulao, Roti",
                          ),
                          const SizedBox(height: 14),
                          _buildInputField(
                            "Snacks Items",
                            controller.formControllers[controller
                                .selectedDay
                                .value]!['snacks']!,
                            "e.g. Pani Puri, Tea",
                          ),
                          const SizedBox(height: 14),
                          _buildInputField(
                            "Dinner Items",
                            controller.formControllers[controller
                                .selectedDay
                                .value]!['dinner']!,
                            "e.g. Soya Chilli, Dal Fry, Jalebi",
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 🚀 PUBLISH BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.publishMenu(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Publish Monthly Menu",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      maxLines: 2,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 11.5,
          color: Colors.grey.shade400,
        ),
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}