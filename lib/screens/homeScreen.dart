import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:ami_admin/screens/AdminMenuUploadScreen.dart';
import 'package:ami_admin/screens/DayScholarOrdersScreen.dart';
import 'package:ami_admin/screens/Skip%20_StatsScreen.dart';
import 'package:ami_admin/screens/student_financial_screen.dart';
import 'package:ami_admin/screens/studetns_feesbackscreen.dart';
import 'package:ami_admin/screens/payment_history_screen.dart';
import 'package:ami_admin/screens/token_history_screen.dart';
import 'package:ami_admin/screens/token_status_scrren.dart';
import 'package:ami_admin/screens/updateing_user_status_screen.dart';
import 'package:ami_admin/screens/payment_requests_screen.dart';

// --- System Notice Controller ---
class SystemNoticeController extends GetxController {
  var isActive = false.obs;
  var title = ''.obs;
  var message = ''.obs;
  var level = 'warning'.obs;
  var isLoading = false.obs;

  static const String statusUrl =
      "https://ami-backend.onrender.com/api/system/status";

  @override
  void onInit() {
    super.onInit();
    fetchNotice();
  }

  Future<void> fetchNotice() async {
    try {
      isLoading.value = true;
      final response = await http
          .get(Uri.parse(statusUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notice = data['data']?['maintenanceNotice'];
        if (notice != null && notice['isActive'] == true) {
          isActive.value = true;
          title.value = notice['title'] ?? 'System Infrastructure Notice';
          message.value = notice['message'] ?? '';
          level.value = notice['level'] ?? 'warning';
        } else {
          isActive.value = false;
        }
      }
    } catch (e) {
      // Keeps the dashboard running cleanly if the network fails
      isActive.value = false;
    } finally {
      isLoading.value = false;
    }
  }
}

// --- Homescreen View ---
class Homescreen extends StatelessWidget {
  Homescreen({super.key});

  final SystemNoticeController noticeCtrl = Get.put(
    SystemNoticeController(),
    permanent: true,
  );

  static const Color chefYellow = Color(0xFFFFC800);
  static const Color background = Color(0xFFF7F8FA);
  static const Color textPrimary = Color(0xFF171A21);
  static const Color textSecondary = Color(0xFF737B8C);
  static const Color borderColor = Color(0xFFE2E6EC);

  static const Color teal = Color(0xFF00897B);
  static const Color orange = Color(0xFFE58F00);
  static const Color greyBlue = Color(0xFF546E7A);
  static const Color green = Color(0xFF2E7D32);
  static const Color red = Color(0xFFD84315);
  static const Color purple = Color(0xFF7656A6);
  static const Color blue = Color(0xFF3949AB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 1000;
          final isDesktop = width >= 1000;

          final columns = isDesktop ? 4 : (isTablet ? 2 : 1);
          final horizontalPadding = isMobile ? 14.0 : (isTablet ? 22.0 : 26.0);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isMobile ? 16 : 24,
                  horizontalPadding,
                  isMobile ? 14 : 24,
                ),
                child: Column(
                  children: [
                    // Dynamic Server/Database Notice Banner
                    _buildSystemNoticeBanner(isMobile),

                    _buildDashboardHeader(
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isMobile ? 14 : 20),
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: isMobile ? 10 : 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: isMobile ? 10 : 16,
                          mainAxisSpacing: isMobile ? 10 : 16,
                          childAspectRatio: _getCardAspectRatio(width),
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return _buildMenuItem(index, isMobile: isMobile);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Dynamic Warning Banner Widget ---
  Widget _buildSystemNoticeBanner(bool isMobile) {
    return Obx(() {
      if (!noticeCtrl.isActive.value) return const SizedBox.shrink();

      final isCritical = noticeCtrl.level.value == 'critical';
      final bgColor = isCritical
          ? const Color(0xFFB71C1C)
          : const Color(0xFFE65100);
      final iconBg = isCritical
          ? const Color(0xFF880E4F)
          : const Color(0xFFBF360C);

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: isMobile ? 14 : 18),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 18,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticeCtrl.title.value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isMobile ? 12.5 : 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    noticeCtrl.message.value,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: isMobile ? 10 : 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return AppBar(
      backgroundColor: chefYellow,
      surfaceTintColor: chefYellow,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: isMobile ? 60 : 66,
      titleSpacing: isMobile ? 14 : 20,
      title: Row(
        children: [
          Container(
            width: isMobile ? 36 : 40,
            height: isMobile ? 36 : 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 11),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: Colors.black,
              size: isMobile ? 19 : 21,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ami Hostlers',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: isMobile ? 15 : 16.5,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mess Control Center',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF5C4900),
                  fontSize: isMobile ? 9.5 : 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 12 : 20),
          child: _buildAdminBadge(isMobile),
        ),
      ],
    );
  }

  Widget _buildAdminBadge(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 11,
        vertical: isMobile ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Admin',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: isMobile ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader({
    required bool isMobile,
    required bool isTablet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: isMobile ? 19 : (isTablet ? 22 : 25),
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isMobile
                    ? 'Manage mess operations'
                    : 'Manage your mess operations from one place',
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontSize: isMobile ? 10.5 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          Obx(() {
            final isCritical =
                noticeCtrl.isActive.value &&
                noticeCtrl.level.value == 'critical';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isCritical ? const Color(0xFFE53935) : borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isCritical
                          ? const Color(0xFFE53935)
                          : const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCritical ? 'Attention Required' : 'System Active',
                    style: GoogleFonts.poppins(
                      color: isCritical ? const Color(0xFFE53935) : textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  double _getCardAspectRatio(double width) {
    if (width < 600) return 3.0;
    if (width < 1000) return 2.05;
    return 1.65;
  }

  Widget _buildMenuItem(int index, {required bool isMobile}) {
    switch (index) {
      case 0:
        return _buildMenuCard(
          title: 'Token Dashboard',
          subtitle: 'Real-time meal tracking',
          icon: Icons.dashboard_customize_rounded,
          color: teal,
          isPrimary: true,
          isMobile: isMobile,
          onTap: () => Get.to(() => TokenStatusScreen()),
        );

      case 1:
        return _buildMenuCard(
          title: 'Student Financial',
          subtitle: 'Payments & access management',
          icon: Icons.account_balance_wallet_rounded,
          color: orange,
          isPrimary: true,
          isMobile: isMobile,
          onTap: () => Get.to(() => StudentFinancialScreen()),
        );

      case 2:
        return _buildMenuCard(
          title: 'Payment Requests',
          subtitle: 'Approve UPI screenshots',
          icon: Icons.fact_check_rounded,
          color: const Color(0xFF16A34A),
          isPrimary: true,
          badge: const PendingPaymentsBadge(),
          isMobile: isMobile,
          onTap: () => Get.to(() => const PaymentRequestsScreen()),
        );

      case 3:
        return _buildMenuCard(
          title: 'Token Logs',
          subtitle: 'Full token generation history',
          icon: Icons.history_edu_rounded,
          color: greyBlue,
          isMobile: isMobile,
          onTap: () => Get.to(() => const TokenHistoryScreen()),
        );

      case 4:
        return _buildMenuCard(
          title: 'Revenue Records',
          subtitle: 'Online & offline payments',
          icon: Icons.payments_rounded,
          color: green,
          isMobile: isMobile,
          onTap: () => Get.to(() => const GlobalPaymentHistoryScreen()),
        );

      case 5:
        return _buildMenuCard(
          title: 'Menu Upload',
          subtitle: 'Manage daily food menu',
          icon: Icons.restaurant_menu_rounded,
          color: red,
          isMobile: isMobile,
          onTap: () => Get.to(() => const AdminMenuUploadScreen()),
        );

      case 6:
        return _buildMenuCard(
          title: 'Day Scholar Orders',
          subtitle: 'Manage day scholar orders',
          icon: Icons.set_meal_rounded,
          color: purple,
          isMobile: isMobile,
          onTap: () => Get.to(() => DayScholarOrdersScreen()),
        );

      case 7:
        return _buildMenuCard(
          title: 'Student Feedback',
          subtitle: 'Ratings & student reviews',
          icon: Icons.feedback_rounded,
          color: const Color(0xFFB77900),
          isMobile: isMobile,
          onTap: () => Get.to(() => const StudentsFeedbackScreen()),
        );

      case 8:
        return _buildMenuCard(
          title: 'User Management',
          subtitle: 'Approve & renew access',
          icon: Icons.manage_accounts_rounded,
          color: blue,
          isLast: true,
          isMobile: isMobile,
          onTap: () => Get.to(() => UpdateingUserStatusScreen()),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
    bool isPrimary = false,
    bool isLast = false,
    Widget? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 17),
        hoverColor: chefYellow.withValues(alpha: 0.035),
        splashColor: chefYellow.withValues(alpha: 0.08),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 13 : 20,
            vertical: isMobile ? 10 : 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 17),
            border: Border.all(
              color: isPrimary
                  ? chefYellow.withValues(alpha: 0.85)
                  : isLast
                  ? const Color(0xFFD6DCE6)
                  : borderColor,
              width: isPrimary ? 1.35 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 43 : 62,
                height: isMobile ? 43 : 62,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(isMobile ? 11 : 16),
                ),
                child: Icon(icon, color: color, size: isMobile ? 21 : 29),
              ),
              SizedBox(width: isMobile ? 10 : 17),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: textPrimary,
                              fontSize: isMobile ? 12.5 : 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: chefYellow,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'MAIN',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        if (badge != null) ...[const SizedBox(width: 6), badge],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: isMobile ? 9.5 : 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: isMobile ? 30 : 40,
                height: isMobile ? 30 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(isMobile ? 9 : 11),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isMobile ? 11 : 14,
                  color: const Color(0xFF89909E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
