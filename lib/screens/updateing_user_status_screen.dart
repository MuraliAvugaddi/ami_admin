import 'package:ami_admin/controllers/updateing_user_status_controller.dart';
import 'package:ami_admin/models/user_models.dart';
import 'package:ami_admin/screens/payment_notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateingUserStatusScreen extends StatelessWidget {
  UpdateingUserStatusScreen({super.key});
  final AdminController controller = Get.put(AdminController());

  @override
  Widget build(BuildContext context) {
    // ⚠️ First tap anywhere shows the payment notice; screen unlocks after "I understand".
    return PaymentNoticeGate(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xffF4F7FE),
          appBar: AppBar(
            toolbarHeight: 65,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Student Directory",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Manage mess access & renewals",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            actions: [
              _buildHeaderAction(
                icon: Icons.power_settings_new,
                color: Colors.red,
                onTap: () => controller.showDeactivateAllDialog(context),
                tooltip: "Reset Month",
              ),
              const SizedBox(width: 4),
              _buildHeaderAction(
                icon: Icons.refresh,
                color: const Color(0xffFFC800),
                onTap: () => controller.fetchUsers(),
                tooltip: "Sync Data",
              ),
              const SizedBox(width: 12),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(45),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: TabBar(
                  isScrollable: true,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xffFFC800),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(child: _tabLabel("Active Students", Icons.verified_user)),
                    Tab(child: _tabLabel("Expired/Pending", Icons.error_outline)),
                  ],
                ),
              ),
            ),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  // --- ⚠️ PAYMENT / SERVER NOTICE ---
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: PaymentNoticeBanner(),
                  ),

                  // --- 📊 STATS ROW ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Obx(() {
                      int total = controller.totalUsersCount;
                      int active = controller.totalActiveCount;
                      int expired = controller.totalInactiveCount;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildHeaderStatChip(
                              "Total",
                              total.toString(),
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeaderStatChip(
                              "Active",
                              active.toString(),
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeaderStatChip(
                              "No Access",
                              expired.toString(),
                              Colors.red,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  // --- 🔍 SEARCH BAR ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: controller.updateSearchQuery,
                        decoration: InputDecoration(
                          hintText: "Search by phone, name, or enrollment...",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xffFFC800),
                            size: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- 📋 GRID CONTENT ---
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildResponsiveGrid(context, controller, true),
                        _buildResponsiveGrid(context, controller, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(
    BuildContext context,
    AdminController controller,
    bool showActive,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xffFFC800)),
        );
      }

      final users = showActive
          ? controller.activeUsers
          : controller.expiredUsers;

      if (users.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              "No results found in this category",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
            ),
          ],
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1100
              ? 3
              : (MediaQuery.of(context).size.width > 700 ? 2 : 1),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 215,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) =>
            UserStatusCard(user: users[index], controller: controller),
      );
    });
  }
}

class UserStatusCard extends StatefulWidget {
  final AppUser user;
  final AdminController controller;
  const UserStatusCard({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  State<UserStatusCard> createState() => _UserStatusCardState();
}

class _UserStatusCardState extends State<UserStatusCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isHovered
            ? (Matrix4.identity()..translate(0, -3, 0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFC800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Obx(() {
                        bool isActive = widget.user.hasValidAccess;
                        return Text(
                          isActive ? "ACTIVE" : "EXPIRED",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.badge_outlined, widget.user.enrollmentNo),
            _infoRow(Icons.phone_android_outlined, widget.user.phonenumber),
            _infoRow(Icons.room_outlined, "Room ${widget.user.room}"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: Obx(() {
                bool isActive = widget.user.hasValidAccess;
                return ElevatedButton(
                  onPressed: () =>
                      widget.controller.toggleApproval(widget.user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.green.shade600
                        : Colors.red.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isActive ? "REVOKE ACCESS" : "RENEW ACCESS",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}