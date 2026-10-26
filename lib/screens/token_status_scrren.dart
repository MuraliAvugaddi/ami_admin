import 'package:ami_admin/controllers/token_controller.dart';
import 'package:ami_admin/screens/payment_notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TokenStatusScreen extends StatelessWidget {
  TokenStatusScreen({super.key});
  final TokenStatsController controller = Get.put(TokenStatsController());

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 800;

    // ⚠️ First tap anywhere shows the payment notice; screen unlocks after "I understand".
    return PaymentNoticeGate(
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FA),
        appBar: AppBar(
          title: Text(
            "Token Analytics",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: const Color(0xffFFC800),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.black),
              onPressed: () => controller.fetchDashboardData(),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xffFFC800)),
            );
          }
          if (controller.errorMessage.value.isNotEmpty) {
            return Center(
              child: Text(
                controller.errorMessage.value,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 1200,
              ), // Centers dashboard on wide web screens
              child: CustomScrollView(
                slivers: [
                  // --- ⚠️ PAYMENT / SERVER NOTICE ---
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: PaymentNoticeBanner(),
                    ),
                  ),

                  // 1. Today's Section Header
                  _buildSliverHeader(
                    "Today's Tokens",
                    DateFormat('MMMM d, yyyy').format(DateTime.now()),
                  ),

                  // 2. Today's Responsive Grid
                  _buildResponsiveGrid(controller.todayStats, isWideScreen),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(indent: 20, endIndent: 20),
                    ),
                  ),

                  // 3. Yesterday's Section Header
                  _buildSliverHeader(
                    "Yesterday's Tokens",
                    DateFormat(
                      'MMMM d, yyyy',
                    ).format(DateTime.now().subtract(const Duration(days: 1))),
                  ),

                  // 4. Yesterday's Responsive Grid
                  _buildResponsiveGrid(controller.yesterdayStats, isWideScreen),

                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSliverHeader(String title, String subtitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(Map<String, int> stats, bool isWide) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // 4 columns on Web/Tablet, 2 on Mobile
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          String mealType = stats.keys.elementAt(index);
          int count = stats.values.elementAt(index);
          return StatCard(title: mealType, count: count);
        }, childCount: stats.length),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int count;
  const StatCard({super.key, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            // Ensures text fits perfectly on any screen size
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffFFC800),
                ),
              ),
            ),
          ),
          Text(
            "generated",
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}