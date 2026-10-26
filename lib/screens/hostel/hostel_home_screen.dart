import 'package:ami_admin/apis/hostel_endpoints.dart';
import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/complaints_screen.dart';
import 'package:ami_admin/screens/hostel/hostel_session.dart';
import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/screens/hostel/sos_alarm_screen.dart';
import 'package:ami_admin/screens/hostel/sos_list_screen.dart';
import 'package:ami_admin/screens/hostel/staff_accounts_screen.dart';
import 'package:ami_admin/screens/hostel/staff_notifications_screen.dart';
import 'package:ami_admin/screens/hostel/students_directory_screen.dart';
import 'package:ami_admin/screens/hostel/visitors_screen.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:ami_admin/screens/studetns_feesbackscreen.dart';
import 'package:ami_admin/screens/token_history_screen.dart';
import 'package:ami_admin/screens/token_status_scrren.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// HOSTEL DASHBOARD — director / warden / attender
// Same card style as the mess "Admin Dashboard"
// ============================================================

class HostelHomeScreen extends StatefulWidget {
  const HostelHomeScreen({super.key});

  @override
  State<HostelHomeScreen> createState() => _HostelHomeScreenState();
}

class _HostelHomeScreenState extends State<HostelHomeScreen> {
  final HostelStaffService _service = HostelStaffService();
  final HostelStaffController _live = Get.isRegistered<HostelStaffController>()
      ? Get.find<HostelStaffController>()
      : Get.put(HostelStaffController(), permanent: true);

  Map<String, dynamic> _summary = {};
  Worker? _changes;

  bool get _isDirector => StaffSession.role == 'director';

  /// Director + warden can also see mess tokens & feedback (view only)
  bool get _canSeeMess => ['director', 'warden'].contains(StaffSession.role);

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _changes = ever(_live.changes, (_) => _loadSummary());
  }

  @override
  void dispose() {
    _changes?.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final res = await _service.complaintsSummary();
    if (!mounted || res['success'] != true) return;
    setState(() => _summary = res);
  }

  Future<void> _refresh() async {
    await Future.wait([_loadSummary(), _live.refreshAll()]);
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: _appBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 1000;
          final columns = width >= 1000 ? 3 : (isTablet ? 2 : 1);
          final pad = isMobile ? 14.0 : 22.0;

          return RefreshIndicator(
            color: Colors.black,
            onRefresh: _refresh,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(pad, isMobile ? 16 : 24, pad, 24),
                  children: [
                    _sosBanner(),
                    _header(isMobile),
                    SizedBox(height: isMobile ? 14 : 20),
                    _numbers(isMobile),
                    SizedBox(height: isMobile ? 14 : 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: isMobile ? 10 : 16,
                        mainAxisSpacing: isMobile ? 10 : 16,
                        childAspectRatio: isMobile ? 3.0 : (isTablet ? 2.05 : 2.2),
                      ),
                      itemCount: _menu.length,
                      itemBuilder: (_, i) => _menuCard(_menu[i], isMobile),
                    ),
                    if (_isDirector) ...[
                      const SizedBox(height: 20),
                      _workersCard(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: HostelColors.chefYellow,
      surfaceTintColor: HostelColors.chefYellow,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment_rounded, color: HostelColors.chefYellow, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ami Hostel',
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${StaffSession.name} • ${StaffSession.roleName(StaffSession.role)}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: const Color(0xFF5C4900), fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Obx(
          () => IconButton(
            tooltip: 'Notifications',
            onPressed: () async {
              await Get.to(() => const StaffNotificationsScreen());
              _live.loadUnread();
            },
            icon: Badge(
              isLabelVisible: _live.unread.value > 0,
              label: Text('${_live.unread.value > 99 ? '99+' : _live.unread.value}'),
              child: const Icon(Icons.notifications_rounded, color: Colors.black),
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
          onSelected: (v) {
            if (v == 'test') _live.testAlarm();
            if (v == 'logout') HostelSession.confirmLogout();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'test', child: Text('Test SOS alarm (5 sec)')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
    );
  }

  Widget _sosBanner() {
    return Obx(() {
      final list = _live.activeSos;
      if (list.isEmpty) return const SizedBox.shrink();
      final first = list.first;
      final active = list.where((s) => s['status'] == 'active').length;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: HostelCard(
          color: HostelColors.sosRed,
          border: HostelColors.sosRed,
          onTap: () => Get.to(() => SosAlarmScreen(sosId: '${first['_id']}'), routeName: '/SosAlarmScreen'),
          child: Row(
            children: [
              const Icon(Icons.sos_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active > 0 ? '$active SOS waiting for help!' : '${list.length} SOS — staff on the way',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${first['studentName']} • Block ${first['hostelblock']} • Room ${first['room']}',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      );
    });
  }

  Widget _header(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hostel Dashboard',
          style: GoogleFonts.poppins(
            color: HostelColors.textPrimary,
            fontSize: isMobile ? 19 : 23,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Room repairs, SOS and gate visitors',
          style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: isMobile ? 10.5 : 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _numbers(bool isMobile) {
    String n(String key) => _summary[key] == null ? '–' : '${_summary[key]}';
    final items = [
      ('Open now', n('open'), HostelColors.orange),
      ('At warden', n('atWarden'), HostelColors.purple),
      ('At director', n('atDirector'), HostelColors.red),
      ('Avg fix (h)', n('avgFixHours'), HostelColors.teal),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HostelColors.borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    items[i].$2,
                    style: GoogleFonts.poppins(color: items[i].$3, fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    items[i].$1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  List<_MenuItem> get _menu => [
        _MenuItem('Room Complaints', 'Electric, plumbing, carpentry', Icons.handyman_rounded, HostelColors.orange,
            () => Get.to(() => const ComplaintsScreen()), primary: true),
        _MenuItem('Escalated', StaffSession.role == 'attender' ? 'Late complaints' : 'Needs your action',
            Icons.priority_high_rounded, HostelColors.red, () => Get.to(() => const ComplaintsScreen(startTab: 'escalated')),
            primary: true),
        _MenuItem('SOS Alerts', 'Emergency history', Icons.sos_rounded, HostelColors.sosRed, () => Get.to(() => const SosListScreen()),
            primary: true),
        _MenuItem('Visitor Register', 'Gate entries & check-out', Icons.badge_rounded, HostelColors.teal,
            () => Get.to(() => const VisitorsScreen())),
        _MenuItem('Students', 'Find room & call parents', Icons.groups_rounded, HostelColors.blue,
            () => Get.to(() => const StudentsDirectoryScreen())),
        if (_isDirector)
          _MenuItem('Staff Accounts', 'Add warden, attender, workers', Icons.manage_accounts_rounded, HostelColors.purple,
              () => Get.to(() => const StaffAccountsScreen())),
        _MenuItem('Gate QR Poster', 'Print & stick at the gate', Icons.qr_code_2_rounded, HostelColors.greyBlue,
            () => launchUrl(Uri.parse(HostelEndpoints.gateQrPage), mode: LaunchMode.externalApplication)),

        // ---- MESS (view only, same screens as mess admin) ----
        if (_canSeeMess) ...[
          _MenuItem('Mess Tokens Today', 'Generated vs eaten, live', Icons.dashboard_customize_rounded,
              const Color(0xFF00897B), () => Get.to(() => TokenStatusScreen())),
          _MenuItem('Token History', 'Who ate which meal, by date', Icons.history_edu_rounded,
              HostelColors.greyBlue, () => Get.to(() => const TokenHistoryScreen())),
          _MenuItem('Mess Feedback', 'Student ratings & remarks', Icons.feedback_rounded,
              const Color(0xFFB77900), () => Get.to(() => const StudentsFeedbackScreen())),
        ],
      ];

  Widget _menuCard(_MenuItem m, bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: m.onTap,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 17),
        splashColor: HostelColors.chefYellow.withValues(alpha: 0.08),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 13 : 20, vertical: isMobile ? 10 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 17),
            border: Border.all(
              color: m.primary ? HostelColors.chefYellow.withValues(alpha: 0.85) : HostelColors.borderColor,
              width: m.primary ? 1.35 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.045), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 43 : 58,
                height: isMobile ? 43 : 58,
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(isMobile ? 11 : 15),
                ),
                child: Icon(m.icon, color: m.color, size: isMobile ? 21 : 27),
              ),
              SizedBox(width: isMobile ? 10 : 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: HostelColors.textPrimary,
                        fontSize: isMobile ? 13.5 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      m.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: isMobile ? 10.5 : 11.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: isMobile ? 13 : 15, color: const Color(0xFFB8BFCA)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workersCard() {
    final workers = asMapList(_summary['workers']);
    if (workers.isEmpty) return const SizedBox.shrink();
    final rating = _summary['avgRating'];
    return HostelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Repair team — last 30 days',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: HostelColors.textPrimary),
                ),
              ),
              if (rating != null) HostelChip('★ $rating avg', color: const Color(0xFFB88A00)),
            ],
          ),
          const SizedBox(height: 8),
          for (final w in workers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Icon(Icons.engineering_rounded, size: 18, color: HostelColors.greyBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${w['name']}  ·  ${StaffSession.tradeName('${w['trade'] ?? ''}')}',
                      style: GoogleFonts.poppins(fontSize: 12.5),
                    ),
                  ),
                  Text(
                    '${w['done']}/${w['jobs']} done',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: HostelColors.green),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool primary;

  _MenuItem(this.title, this.subtitle, this.icon, this.color, this.onTap, {this.primary = false});
}
