import 'package:ami_admin/controllers/DayScholarOrdersController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DayScholarOrdersScreen extends StatelessWidget {
  const DayScholarOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DayScholarOrdersController());
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(
          "Day Scholar Plate Orders",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xffFFC800),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ), // Perfect desktop containment
          child: Column(
            children: [
              // 1. Desktop & Mobile Responsive Filters (Meal Type & Date Picker)
              _buildFilterBar(context, controller),

              // 2. Summary Stats Header Card
              Obx(() => _buildSummaryCard(controller)),

              // 3. List of Day Scholar Orders
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xffFFC800),
                      ),
                    );
                  }
                  if (controller.orders.isEmpty) {
                    return Center(
                      child: Text(
                        "No day scholar meal orders found for this selection",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    );
                  }

                  // Use GridView for wide/desktop screens if preferred, or a clean constrained ListView
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: controller.orders.length,
                    itemBuilder: (context, index) {
                      final order = controller.orders[index];
                      final user = order['userId'] ?? {};
                      final DateTime orderedAt = DateTime.parse(
                        order['orderedAt'],
                      ).toLocal();

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    user['name'] ?? "Unknown Student",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMealColor(order['mealType']),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order['mealType'].toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    "ID: ${user['enrollmentNo'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "Year: ${user['year'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "Room: ${user['room'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "Ph: ${user['phonenumber'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Token: ${order['tokenNumber']}",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                      Text(
                                        "Txn ID: ${order['transactionId']}",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy, hh:mm a',
                                        ).format(orderedAt),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "₹${order['totalAmount']}",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMealColor(String meal) {
    switch (meal) {
      case 'Breakfast':
        return Colors.orange;
      case 'Lunch':
        return Colors.green;
      case 'Snacks':
        return Colors.purple;
      case 'Dinner':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilterBar(
    BuildContext context,
    DayScholarOrdersController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Meal Type Selector Filter
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              icon: const Icon(Icons.fastfood, size: 16, color: Colors.amber),
              label: Obx(
                () => Text("Meal: ${controller.selectedMealType.value}"),
              ),
              onPressed: () {
                Get.bottomSheet(
                  _pickerSheet(
                    "Select Meal Filter",
                    ["All", "Breakfast", "Lunch", "Snacks", "Dinner"],
                    (val) {
                      controller.updateFilters(mealType: val);
                      Get.back();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Calendar Date Picker Filter
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
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
                      ? "Filter by Date"
                      : DateFormat(
                          'dd MMM yyyy',
                        ).format(controller.selectedDate.value!),
                ),
              ),
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate.value ?? DateTime.now(),
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xffFFC800), // header background color
                          onPrimary: Colors.black, // header text color
                          onSurface: Colors.black, // body text color
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  controller.updateFilters(date: pickedDate);
                }
              },
            ),
          ),
          // Clear Date filter button if date is active
          Obx(
            () => controller.selectedDate.value != null
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () => controller.updateFilters(clearDate: true),
                    tooltip: "Clear Date Filter",
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _pickerSheet(
    String title,
    List<String> options,
    Function(String) onSelect,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          const SizedBox(height: 10),
          ...options.map(
            (opt) => ListTile(title: Text(opt), onTap: () => onSelect(opt)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DayScholarOrdersController controller) {
    final stats = controller.stats;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xff2D2D2D)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Day Scholar Revenue",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${stats['totalCollection'] ?? 0}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Total Orders: ${stats['totalOrders'] ?? 0}",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "B: ${stats['breakfastCount'] ?? 0} | L: ${stats['lunchCount'] ?? 0} | S: ${stats['snacksCount'] ?? 0} | D: ${stats['dinnerCount'] ?? 0}",
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
