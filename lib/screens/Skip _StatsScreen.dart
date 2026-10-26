import 'package:ami_admin/controllers/skip_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminMealReportScreen extends StatelessWidget {
  const AdminMealReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SkipReportController());
    // Determine if we are on a wide screen (Web/Tablet)
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(
          "Food Waste Prevention",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xffFFC800),
        centerTitle: true,
        elevation: 0,
      ),
      // Using CustomScrollView to handle responsiveness and prevent overflow
      body: CustomScrollView(
        slivers: [
          // 1. Sticky Header for Date Selection
          SliverToBoxAdapter(child: _buildFilterHeader(context, controller)),

          // 2. Responsive Stats Dashboard
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Obx(
              () => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // Web gets 6 columns, Mobile gets 3
                  crossAxisCount: isWideScreen ? 6 : 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWideScreen ? 1.5 : 1.2,
                ),
                delegate: SliverChildListDelegate([
                  _buildStatCard(
                    "Breakfast",
                    controller.getCount("Breakfast"),
                    Colors.orange,
                  ),
                  _buildStatCard(
                    "Lunch",
                    controller.getCount("Lunch"),
                    Colors.green,
                  ),
                  _buildStatCard(
                    "Snacks",
                    controller.getCount("Snacks"),
                    Colors.blue,
                  ),
                  _buildStatCard(
                    "Dinner",
                    controller.getCount("Dinner"),
                    Colors.indigo,
                  ),
                  _buildStatCard(
                    "Full Day",
                    controller.getCount("Full Day"),
                    Colors.red,
                  ),
                  _buildStatCard("Total", controller.totalSkips, Colors.black),
                ]),
              ),
            ),
          ),

          // 3. Section Title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
          ),

          // 4. Scrollable List of Students
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xffFFC800)),
                ),
              );
            }
            if (controller.skipList.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "No skips reported for this day.",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final skip = controller.skipList[index];
                  final user = skip['userId'];

                  return Center(
                    // Constraints list width on Web
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: const Icon(
                              Icons.person_off_outlined,
                              color: Colors.red,
                            ),
                          ),
                          title: Text(
                            user['name'] ?? "Unknown",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "Room: ${user['room']} • ${user['phonenumber']}\nSkipping: ${skip['mealType']}",
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: Chip(
                            label: Text(
                              user['gender'] ?? "",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.grey[100],
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: controller.skipList.length),
              ),
            );
          }),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1),),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          FittedBox(
            // Prevents text overflow on small grid cells
            child: Text(
              "$count",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(
    BuildContext context,
    SkipReportController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => Text(
              DateFormat(
                'EEE, dd MMM yyyy',
              ).format(controller.selectedDate.value),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null)
                controller.updateFilters(
                  date,
                  controller.selectedMealType.value,
                );
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text("Change Date"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFFC800),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
