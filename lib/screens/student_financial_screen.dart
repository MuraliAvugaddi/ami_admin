import 'dart:convert';
import 'dart:io' as io;
import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:ami_admin/controllers/updateing_user_status_controller.dart';
import 'package:ami_admin/screens/StudentPaymentRequestsPanel.dart';
import 'package:ami_admin/screens/payment_requests_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ami_admin/screens/student_receipts_view.dart';
import 'package:ami_admin/screens/cash_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

import '../apis/api_endpoints.dart';
import '../models/user_models.dart';

class ChefColors {
  static const primary = Color(0xFFFFC800);
  static const primaryDark = Color(0xFF9A7600);
  static const primarySoft = Color(0xFFFFF6CC);

  static const background = Color(0xFFF6F8FC);
  static const surface = Colors.white;
  static const border = Color(0xFFE5EAF2);

  static const text = Color(0xFF172033);
  static const muted = Color(0xFF667085);

  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFEAF8EF);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFFEEEE);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF7E6);
}

class _MetricData {
  final String title;
  final String count;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _MetricData({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class StudentFinancialScreen extends StatefulWidget {
  const StudentFinancialScreen({super.key});

  @override
  State<StudentFinancialScreen> createState() => _StudentFinancialScreenState();
}

class _StudentFinancialScreenState extends State<StudentFinancialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final AdminController adminController = Get.put(AdminController());

  // Comprehensive filter categories requested by client
  String selectedFilterCategory = 'All';
  String selectedMonth = 'October 2026';
  bool showUnpaidOnly = false;

  final Set<String> _currentMonthPaidUserIds = {};
  final Map<String, Map<String, String>> _userPaymentMap = {};
  bool _isLoadingPayments = false;

  /// Students who uploaded a payment screenshot that is waiting for approval
  Set<String> _pendingUserIds = {};

  static const List<String> _filterCategories = [
    'All',
    'All Boys',
    'Junior Boys',
    'Senior Boys',
    'All Girls',
    'Junior Girls',
    'Senior Girls',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // ✅ Automatic: August 2026 → 2 months after today (November, December... appear by themselves)
  List<String> get monthsList => ['All Year', ..._monthsUntil(2)];

  bool _isRealUtrNumber(String val) {
    final clean = val.trim().toLowerCase();
    if (clean.isEmpty ||
        clean == 'unpaid' ||
        clean == 'pending' ||
        clean == 'due' ||
        clean == 'none' ||
        clean == 'null' ||
        clean == 'n/a' ||
        clean == 'na' ||
        clean.startsWith('cash')) {
      return false;
    }
    final digitsOnly = clean.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 6;
  }

  bool _isJunior(AppUser u) => u.year == '1' || u.year.contains('1');
  bool _isBoy(AppUser u) => u.gender.trim().toLowerCase() == 'male';
  bool _isGirl(AppUser u) => u.gender.trim().toLowerCase() == 'female';

  bool _matchesSelectedCategory(AppUser u) {
    switch (selectedFilterCategory) {
      case 'All Boys':
        return _isBoy(u);
      case 'Junior Boys':
        return _isBoy(u) && _isJunior(u);
      case 'Senior Boys':
        return _isBoy(u) && !_isJunior(u);
      case 'All Girls':
        return _isGirl(u);
      case 'Junior Girls':
        return _isGirl(u) && _isJunior(u);
      case 'Senior Girls':
        return _isGirl(u) && !_isJunior(u);
      case 'All':
      default:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final now = DateTime.now();
    selectedMonth = '${_monthNames[now.month - 1]} ${now.year}';

    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    adminController.fetchUsers();
    _fetchPendingScreenshots();
    await _fetchGlobalPayments();
  }

  Future<void> _fetchPendingScreenshots() async {
    try {
      final uri = Uri.parse(ApiEndpoints.paymentSubmissions).replace(queryParameters: {'status': 'pending'});
      final res = await http.get(uri);
      final d = jsonDecode(res.body);
      if (res.statusCode == 200 && d['success'] == true && mounted) {
        final ids = <String>{};
        for (final s in (d['submissions'] ?? const [])) {
          final u = s['userId'];
          final id = u is Map ? '${u['_id'] ?? ''}' : '${u ?? ''}';
          if (id.isNotEmpty) ids.add(id);
        }
        setState(() => _pendingUserIds = ids);
      }
    } catch (_) {}
  }

  /// Blue "new screenshot" button on a student row → opens the payment dialog
  Widget _pendingScreenshotButton(AppUser student, {double size = 19}) {
    if (!_pendingUserIds.contains(student.id)) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'New payment screenshot — tap to approve / reject',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () => _showManualPaymentDialog(student),
      icon: Badge(
        backgroundColor: const Color(0xFF2563EB),
        smallSize: 8,
        child: Icon(Icons.mark_email_unread_rounded, color: const Color(0xFF2563EB), size: size),
      ),
    );
  }

  Future<void> _fetchGlobalPayments() async {
    try {
      setState(() => _isLoadingPayments = true);
      final response = await http.get(
        Uri.parse('${ApiEndpoints.adminAllPayments}?month=All Year'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List payments = (data is List) ? data : (data['payments'] ?? []);

        _userPaymentMap.clear();

        for (var p in payments) {
          final status = (p['status'] ?? '').toString().trim().toLowerCase();
          final amount = num.tryParse((p['amount'] ?? 0).toString()) ?? 0;
          final mName = (p['month'] ?? '').toString().trim();
          final txn = (p['transactionId'] ?? '').toString().trim();

          if ((status == 'success' ||
                  (txn.isNotEmpty &&
                      txn.toLowerCase() != 'unpaid' &&
                      txn != 'N/A' &&
                      txn != 'n/a')) &&
              amount > 0) {
            String uid = '';
            if (p['userId'] is Map) {
              uid = (p['userId']['_id'] ?? p['userId']['id'] ?? '').toString();
            } else {
              uid = (p['userId'] ?? '').toString();
            }

            if (uid.isNotEmpty) {
              _userPaymentMap.putIfAbsent(uid, () => {})[mName.toLowerCase()] =
                  txn;
            }
          }
        }

        _recalculateCurrentMonthPaidSet();
      }
    } catch (e) {
      debugPrint('Error loading payments: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPayments = false);
      }
    }
  }

  void _recalculateCurrentMonthPaidSet() {
    _currentMonthPaidUserIds.clear();
    final isAllYear = selectedMonth.toLowerCase().trim() == 'all year';
    final monthsTillNow = _monthsUntil(0); // Aug 2026 → this month

    _userPaymentMap.forEach((uid, monthMap) {
      if (isAllYear) {
        // Paid for every month from August 2026 till now
        if (monthsTillNow.every((m) => _utrFor(monthMap, m) != null)) {
          _currentMonthPaidUserIds.add(uid);
        }
      } else if (_utrFor(monthMap, selectedMonth) != null) {
        _currentMonthPaidUserIds.add(uid);
      }
    });
  }

  Future<void> _confirmDeleteStudent(AppUser student) async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: ChefColors.danger),
            const SizedBox(width: 8),
            Text(
              'Delete Student',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${student.name}" (Room: ${student.room})? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, color: ChefColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: ChefColors.muted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final res = await http.delete(
                  Uri.parse('${ApiEndpoints.adminUsers}/${student.id}'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}',
                  },
                );

                if (res.statusCode == 200) {
                  await _loadAllData();
                  Get.snackbar(
                    'Student Deleted',
                    '${student.name} has been removed from the mess database.',
                    backgroundColor: ChefColors.danger,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(12),
                  );
                } else {
                  Get.snackbar(
                    'Delete Failed',
                    'Could not delete student (${res.statusCode})',
                    backgroundColor: ChefColors.danger,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Network error deleting student: $e',
                  backgroundColor: ChefColors.danger,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChefColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: ChefColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ChefColors.primary,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: ChefColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: ChefColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: ChefColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: ChefColors.muted),
          hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
        ),
      ),
      child: Scaffold(
        backgroundColor: ChefColors.background,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 650;
              final isTablet = width >= 650 && width < 1050;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Column(
                    children: [
                      _buildMetricsSummaryBar(isMobile),
                      _buildFilterToolbar(isMobile, isTablet),
                      _buildTabs(isMobile),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStudentListView(
                              isJunior: true,
                              isCompact: isMobile,
                            ),
                            _buildStudentListView(
                              isJunior: false,
                              isCompact: isMobile,
                            ),
                          ],
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ChefColors.primary,
      surfaceTintColor: ChefColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      titleSpacing: 0,
      leadingWidth: 44,
      leading: IconButton(
        tooltip: 'Back',
        padding: EdgeInsets.zero,
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else if (Get.key.currentState?.canPop() == true) {
            Get.back();
          }
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1A1A1A),
          size: 18,
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          'Student Finance',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadAllData,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF1A1A1A),
            size: 21,
          ),
        ),
        Builder(
          builder: (context) {
            final mobile = MediaQuery.sizeOf(context).width < 650;

            if (mobile) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  tooltip: 'Export Excel',
                  onPressed: () => _exportExcel(),
                  icon: Icon(
                    showUnpaidOnly
                        ? Icons.warning_amber_rounded
                        : Icons.file_download_outlined,
                    color: const Color(0xFF1A1A1A),
                    size: 21,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildExcelExportButton(),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: ChefColors.primaryDark.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isCompact) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 12 : 28,
        7,
        isCompact ? 12 : 28,
        7,
      ),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8EE)),
      ),
      child: SizedBox(
        height: isCompact ? 42 : 44,
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: ChefColors.primary,
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          labelColor: const Color(0xFF211B00),
          unselectedLabelColor: ChefColors.muted,
          labelStyle: GoogleFonts.poppins(
            fontSize: isCompact ? 10.5 : 11.5,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: isCompact ? 10.5 : 11.5,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Juniors · 1st Year'),
            Tab(text: 'Seniors · 2nd–5th Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSummaryBar(bool isCompact) {
    return Obx(() {
      final allUsers = adminController.filteredUsers;
      final selectedCohort = allUsers.where(_matchesSelectedCategory).toList();

      final totalCount = selectedCohort.length;
      final activeCount = selectedCohort
          .where((u) => _currentMonthPaidUserIds.contains(u.id))
          .length;
      final noAccessCount = totalCount - activeCount;

      final categoryLabel = selectedFilterCategory == 'All'
          ? 'Total Students'
          : selectedFilterCategory;

      final cards = [
        _MetricData(
          title: categoryLabel,
          count: totalCount.toString(),
          icon: Icons.groups_rounded,
          iconBackground: ChefColors.primarySoft,
          iconColor: ChefColors.primaryDark,
        ),
        _MetricData(
          title: 'Paid',
          count: activeCount.toString(),
          icon: Icons.verified_rounded,
          iconBackground: ChefColors.successSoft,
          iconColor: ChefColors.success,
        ),
        _MetricData(
          title: 'Pending',
          count: noAccessCount.toString(),
          icon: Icons.priority_high_rounded,
          iconBackground: ChefColors.warningSoft,
          iconColor: ChefColors.warning,
        ),
      ];

      if (isCompact) {
        return SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) => SizedBox(
              width: 154,
              child: _buildMetricCard(
                title: cards[index].title,
                count: cards[index].count,
                icon: cards[index].icon,
                iconBackground: cards[index].iconBackground,
                iconColor: cards[index].iconColor,
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
        child: Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: cards[i].title,
                  count: cards[i].count,
                  icon: cards[i].icon,
                  iconBackground: cards[i].iconBackground,
                  iconColor: cards[i].iconColor,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ChefColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: ChefColors.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: ChefColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 3, 12, 2),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: ChefColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 47,
              child: TextField(
                onChanged: adminController.updateSearchQuery,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: ChefColors.text,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: ChefColors.primaryDark,
                    size: 21,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: ChefColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: ChefColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: ChefColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    value: selectedFilterCategory,
                    icon: Icons.filter_alt_outlined,
                    items: _filterCategories,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedFilterCategory = value;
                          if (value.contains('Junior') &&
                              _tabController.index != 0) {
                            _tabController.animateTo(0);
                          } else if (value.contains('Senior') &&
                              _tabController.index != 1) {
                            _tabController.animateTo(1);
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _buildFilterDropdown(
                    value: selectedMonth,
                    icon: Icons.calendar_month_outlined,
                    items: monthsList,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                          _recalculateCurrentMonthPaidSet();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Align(alignment: Alignment.centerLeft, child: _buildUnpaidFilter()),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(isTablet ? 18 : 28, 8, isTablet ? 18 : 28, 0),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChefColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: adminController.updateSearchQuery,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: ChefColors.text,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Search name, phone or student ID',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: ChefColors.primaryDark,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: isTablet ? 165 : 185,
            child: _buildFilterDropdown(
              value: selectedFilterCategory,
              icon: Icons.filter_alt_outlined,
              items: _filterCategories,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilterCategory = value;
                    if (value.contains('Junior') && _tabController.index != 0) {
                      _tabController.animateTo(0);
                    } else if (value.contains('Senior') &&
                        _tabController.index != 1) {
                      _tabController.animateTo(1);
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: isTablet ? 155 : 175,
            child: _buildFilterDropdown(
              value: selectedMonth,
              icon: Icons.calendar_month_outlined,
              items: monthsList,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedMonth = value;
                    _recalculateCurrentMonthPaidSet();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 9),
          _buildUnpaidFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;

    return SizedBox(
      height: 45,
      child: DropdownButtonFormField<String>(
        value: effectiveValue,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: ChefColors.muted,
          size: 19,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 0,
          ),
          prefixIcon: Icon(icon, size: 17, color: ChefColors.primaryDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ChefColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ChefColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ChefColors.primary, width: 1.3),
          ),
        ),
        style: GoogleFonts.poppins(
          color: ChefColors.text,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildUnpaidFilter() {
    return FilterChip(
      selected: showUnpaidOnly,
      showCheckmark: false,
      avatar: Icon(
        showUnpaidOnly
            ? Icons.check_circle_rounded
            : Icons.error_outline_rounded,
        size: 16,
        color: showUnpaidOnly ? const Color(0xFF8A6800) : ChefColors.muted,
      ),
      label: const Text('Unpaid only'),
      selectedColor: ChefColors.primarySoft,
      backgroundColor: const Color(0xFFF9FAFC),
      side: BorderSide(
        color: showUnpaidOnly ? ChefColors.primary : ChefColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      labelStyle: GoogleFonts.poppins(
        color: showUnpaidOnly ? const Color(0xFF6B5200) : ChefColors.text,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (value) => setState(() => showUnpaidOnly = value),
    );
  }

  Widget _buildStudentListView({
    required bool isJunior,
    required bool isCompact,
  }) {
    return Obx(() {
      if (adminController.isLoading.value || _isLoadingPayments) {
        return const Center(
          child: CircularProgressIndicator(
            color: ChefColors.primary,
            strokeWidth: 2.5,
          ),
        );
      }

      final filtered = adminController.filteredUsers.where((u) {
        final matchesYear = isJunior ? _isJunior(u) : !_isJunior(u);
        final matchesCategory = _matchesSelectedCategory(u);
        final isPaid = _currentMonthPaidUserIds.contains(u.id);
        final matchesUnpaid = !showUnpaidOnly || !isPaid;

        return matchesYear && matchesCategory && matchesUnpaid;
      }).toList();

      if (filtered.isEmpty) return _buildEmptyState();

      filtered.sort((a, b) {
        return a.name.trim().toLowerCase().compareTo(
          b.name.trim().toLowerCase(),
        );
      });

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 28,
          5,
          isCompact ? 12 : 28,
          24,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final student = filtered[index];
          final isPaid = _currentMonthPaidUserIds.contains(student.id);

          final String currentLetter = student.name.trim().isNotEmpty
              ? student.name.trim()[0].toUpperCase()
              : '#';

          bool showHeader = false;
          if (index == 0) {
            showHeader = true;
          } else {
            final prevStudent = filtered[index - 1];
            final String prevLetter = prevStudent.name.trim().isNotEmpty
                ? prevStudent.name.trim()[0].toUpperCase()
                : '#';
            if (currentLetter != prevLetter) {
              showHeader = true;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) _buildLetterHeader(currentLetter, isCompact),
              _buildStudentCard(student, isPaid: isPaid, isCompact: isCompact),
              const SizedBox(height: 9),
            ],
          );
        },
      );
    });
  }

  Widget _buildLetterHeader(String letter, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: ChefColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              letter,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: ChefColors.border)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    AppUser student, {
    required bool isPaid,
    required bool isCompact,
  }) {
    final initial = student.name.trim().isNotEmpty
        ? student.name.trim()[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _showManualPaymentDialog(student),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isPaid ? const Color(0xFFE3E9E7) : const Color(0xFFE9E6DF),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: isCompact
              ? _buildCompactStudentContent(student, initial, isPaid)
              : _buildDesktopStudentContent(student, initial, isPaid),
        ),
      ),
    );
  }

  Widget _buildDesktopStudentContent(
    AppUser student,
    String initial,
    bool isPaid,
  ) {
    return Row(
      children: [
        _buildAvatar(initial, isPaid),
        const SizedBox(width: 13),
        Expanded(child: _buildStudentDetails(student, isPaid)),
        const SizedBox(width: 14),
        _buildStudentActions(student, isPaid),
      ],
    );
  }

  Widget _buildCompactStudentContent(
    AppUser student,
    String initial,
    bool isPaid,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(initial, isPaid),
            const SizedBox(width: 11),
            Expanded(child: _buildStudentDetails(student, isPaid)),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showManualPaymentDialog(student),
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text('Payment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ChefColors.primaryDark,
                  side: const BorderSide(color: ChefColors.primary, width: 1.2),
                  minimumSize: const Size(0, 40),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => adminController.toggleApproval(student),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaid
                      ? ChefColors.dangerSoft
                      : ChefColors.primary,
                  foregroundColor: isPaid
                      ? ChefColors.danger
                      : const Color(0xFF2A2200),
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  isPaid ? 'Revoke' : 'Grant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Receipts & screenshots',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => showStudentReceipts(context, userId: student.id, name: student.name),
              icon: const Icon(Icons.image_search_rounded, color: ChefColors.primaryDark, size: 19),
            ),
            _pendingScreenshotButton(student),
            IconButton(
              tooltip: 'Cash payment',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () async {
                if (await showCashPaymentDialog(context, userId: student.id, name: student.name)) {
                  _loadAllData();
                }
              },
              icon: const Icon(Icons.payments_rounded, color: ChefColors.success, size: 19),
            ),
            IconButton(
              tooltip: 'Delete Student',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: ChefColors.danger,
                size: 19,
              ),
              onPressed: () => _confirmDeleteStudent(student),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(String initial, bool isPaid) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isPaid
                ? const LinearGradient(
                    colors: [ChefColors.primarySoft, Color(0xFFFFE98A)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFF4F5F7), Color(0xFFECEEF2)],
                  ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.poppins(
              color: isPaid ? ChefColors.primaryDark : ChefColors.muted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: isPaid ? ChefColors.success : ChefColors.warning,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              isPaid ? Icons.check_rounded : Icons.schedule_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDetails(AppUser student, bool isPaid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                student.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: ChefColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildStatusChip(isPaid),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: [
            _infoItem(Icons.badge_outlined, student.enrollmentNo),
            _infoItem(
              Icons.phone_outlined,
              student.phonenumber.isEmpty ? '—' : student.phonenumber,
            ),
            _infoItem(Icons.meeting_room_outlined, 'Room ${student.room}'),
            _infoItem(Icons.person_outline_rounded, student.gender),
            _infoItem(Icons.menu_book_outlined, student.course),
            if (student.fatherPhone.isNotEmpty)
              _infoItem(
                Icons.family_restroom_outlined,
                'Father: ${student.fatherPhone}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF98A2B3)),
        const SizedBox(width: 4),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: ChefColors.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? ChefColors.successSoft : ChefColors.dangerSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 11,
            color: isPaid ? ChefColors.success : ChefColors.danger,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'PAID' : 'UNPAID',
            style: GoogleFonts.poppins(
              color: isPaid ? ChefColors.success : ChefColors.danger,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: .35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentActions(AppUser student, bool isPaid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showManualPaymentDialog(student),
          icon: const Icon(Icons.receipt_long_rounded, size: 16),
          label: const Text('Payment'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ChefColors.primaryDark,
            side: const BorderSide(color: ChefColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Receipts & screenshots',
          onPressed: () => showStudentReceipts(context, userId: student.id, name: student.name),
          icon: const Icon(Icons.image_search_rounded, color: ChefColors.primaryDark, size: 20),
        ),
        _pendingScreenshotButton(student, size: 20),
        IconButton(
          tooltip: 'Cash payment',
          onPressed: () async {
            if (await showCashPaymentDialog(context, userId: student.id, name: student.name)) {
              _loadAllData();
            }
          },
          icon: const Icon(Icons.payments_rounded, color: ChefColors.success, size: 20),
        ),
        const SizedBox(width: 3),
        TextButton(
          onPressed: () => adminController.toggleApproval(student),
          style: TextButton.styleFrom(
            foregroundColor: isPaid ? ChefColors.danger : ChefColors.success,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            textStyle: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Text(isPaid ? 'Revoke' : 'Grant'),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Delete Student',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: ChefColors.danger,
            size: 20,
          ),
          onPressed: () => _confirmDeleteStudent(student),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ChefColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: ChefColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: ChefColors.primaryDark,
                  size: 29,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'No students found',
                style: GoogleFonts.poppins(
                  color: ChefColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Try changing the search, cohort category, month or unpaid filter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: ChefColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // MONTH HELPERS — months are automatic (no more hard-coded Aug/Sep/Oct)
  // ==================================================================

  static const String _firstFeeMonth = 'August 2026';

  String _labelOf(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

  DateTime? _parseMonth(String label) {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    final idx = _monthNames.indexWhere(
      (m) => m.toLowerCase() == parts[0].toLowerCase(),
    );
    final year = int.tryParse(parts[1]);
    if (idx < 0 || year == null) return null;
    return DateTime(year, idx + 1);
  }

  /// From the first fee month (Aug 2026) up to [ahead] months after today.
  List<String> _monthsUntil(int ahead) {
    final start = _parseMonth(_firstFeeMonth) ?? DateTime(2026, 8);
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + ahead);
    final out = <String>[];
    var cur = DateTime(start.year, start.month);
    while (!cur.isAfter(end) && out.length < 60) {
      out.add(_labelOf(cur));
      cur = DateTime(cur.year, cur.month + 1);
    }
    return out;
  }

  /// UTR stored for [label] in a student's payment map (keys are lower-case months).
  String? _utrFor(Map<String, String> monthMap, String label) {
    final want = label.toLowerCase().trim();
    if (monthMap.containsKey(want)) return monthMap[want];
    final p = _parseMonth(label);
    if (p == null) return null;
    final name = _monthNames[p.month - 1].toLowerCase();
    for (final e in monthMap.entries) {
      if (e.key.contains(name) && e.key.contains('${p.year}')) return e.value;
    }
    return null;
  }

  // ==================================================================
  // RECORD / EDIT PAYMENT — 1, 3 or 6 months with one UTR
  // ==================================================================

  Future<void> _showManualPaymentDialog(AppUser student) async {
    // Plan fees (TOTAL): monthly ₹4000, 3 months ₹12000, half semester (6 months) ₹20000
    const planFees = {1: 4000, 3: 12000, 6: 20000};
    num defaultTotal(int n) => planFees[n] ?? 4000 * n;
    final amountController = TextEditingController(text: '4000');
    final fatherPhoneController = TextEditingController(text: student.fatherPhone);
    final dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final utrController = TextEditingController();

    final userPaidSet = _userPaymentMap[student.id] ?? <String, String>{};
    final dialogMonths = _monthsUntil(6); // Aug 2026 → 6 months ahead
    final currentLabel = _labelOf(DateTime.now());

    bool isPaid(String m) => _utrFor(userPaidSet, m) != null;

    // Earlier months this student has not paid (shown as a warning)
    final currentIdx = dialogMonths.indexOf(currentLabel);
    final pastUnpaid = [
      for (var i = 0; i < (currentIdx < 0 ? 0 : currentIdx); i++)
        if (!isPaid(dialogMonths[i])) dialogMonths[i],
    ];

    // Start with the current month selected
    final Set<String> selected = {currentLabel};
    utrController.text = _utrFor(userPaidSet, currentLabel) ?? '';
    String duplicateWarning = '';

    List<String> sortedSelected() {
      final list = selected.toList();
      list.sort((a, b) => (_parseMonth(a) ?? DateTime(0)).compareTo(_parseMonth(b) ?? DateTime(0)));
      return list;
    }

    /// Select [n] consecutive unpaid months starting from the first unpaid month (from today).
    void selectPlan(int n) {
      selected.clear();
      final startIdx = dialogMonths.indexOf(currentLabel);
      var i = startIdx < 0 ? 0 : startIdx;
      while (i < dialogMonths.length && isPaid(dialogMonths[i])) {
        i++;
      }
      for (var k = 0; k < n && i + k < dialogMonths.length; k++) {
        selected.add(dialogMonths[i + k]);
      }
      utrController.text = '';
    }

    // Phone = narrow screen → stacked layout, bigger dialog
    final isPhone = Get.width < 600;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: isPhone
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 16)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600, maxHeight: Get.height * (isPhone ? 0.94 : 0.9)),
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final months = sortedSelected();
              final singlePaid = months.length == 1 && isPaid(months.first);
              final total = num.tryParse(amountController.text.trim()) ?? defaultTotal(months.length);
              final perMonth = months.isEmpty ? 0 : (total / months.length * 100).round() / 100;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------- Header ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ChefColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: ChefColors.primaryDark, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Record / Edit payment',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      color: ChefColors.text,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800)),
                              Text(student.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      color: ChefColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (!isPhone) TextButton.icon(
                          onPressed: () => showStudentReceipts(
                            context,
                            userId: student.id,
                            name: student.name,
                          ),
                          icon: const Icon(Icons.image_search_rounded, size: 16),
                          label: Text('Receipts',
                              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(foregroundColor: ChefColors.primaryDark),
                        ),
                        if (!isPhone) TextButton.icon(
                          onPressed: () async {
                            if (await showCashPaymentDialog(context, userId: student.id, name: student.name)) {
                              Navigator.of(dialogContext).pop();
                              await _loadAllData();
                              _showManualPaymentDialog(student); // reopen with updated months
                            }
                          },
                          icon: const Icon(Icons.payments_rounded, size: 16),
                          label: Text('Cash',
                              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(foregroundColor: ChefColors.success),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  // Phone: Receipts / Cash as two clear buttons under the title
                  if (isPhone)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => showStudentReceipts(context, userId: student.id, name: student.name),
                              icon: const Icon(Icons.image_search_rounded, size: 16),
                              label: Text('Receipts',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ChefColors.primaryDark,
                                side: const BorderSide(color: ChefColors.border),
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (await showCashPaymentDialog(context, userId: student.id, name: student.name)) {
                                  Navigator.of(dialogContext).pop();
                                  await _loadAllData();
                                  _showManualPaymentDialog(student);
                                }
                              },
                              icon: const Icon(Icons.payments_rounded, size: 16),
                              label: Text('Cash payment',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ChefColors.success,
                                side: const BorderSide(color: ChefColors.border),
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1, thickness: 1, color: ChefColors.border),

                  // ---------- Body ----------
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(isPhone ? 14 : 18, 12, isPhone ? 14 : 18, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Screenshots this student uploaded → approve / reject right here
                          StudentPaymentRequestsPanel(
                            userId: student.id,
                            onChanged: () async {
                              Navigator.of(dialogContext).pop();
                              await _loadAllData();
                              _showManualPaymentDialog(student); // reopen with updated months
                            },
                          ),

                          // ✅ Past months not paid
                          if (pastUnpaid.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4F4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF7CACA)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.history_toggle_off_rounded,
                                      size: 16, color: ChefColors.danger),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Past months not paid (${pastUnpaid.length}): ${pastUnpaid.join(', ')}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: ChefColors.danger,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 2,
                            children: [
                              _sectionTitle('Select month(s)', Icons.calendar_month_rounded),
                              if (singlePaid)
                                TextButton.icon(
                                  onPressed: () async {
                                    final monthToReset = months.first;
                                    try {
                                      final res = await http.delete(
                                        Uri.parse(ApiEndpoints.adminDeleteMonthPayment),
                                        headers: {'Content-Type': 'application/json'},
                                        body: jsonEncode({
                                          'userId': student.id,
                                          'month': monthToReset,
                                        }),
                                      );
                                      if (res.statusCode == 200) {
                                        Navigator.of(dialogContext).pop();
                                        await _loadAllData();
                                        Get.snackbar(
                                          'Reset Done',
                                          '$monthToReset has been reset to Unpaid.',
                                          backgroundColor: ChefColors.warning,
                                          colorText: Colors.black,
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      } else {
                                        Get.snackbar('Error', 'Could not reset month payment.');
                                      }
                                    } catch (_) {
                                      Get.snackbar('Error', 'Connection error.');
                                    }
                                  },
                                  icon: const Icon(Icons.undo_rounded, size: 14, color: ChefColors.danger),
                                  label: Text('Reset ${months.first}',
                                      style: GoogleFonts.poppins(
                                          color: ChefColors.danger,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Quick plan buttons
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [1, 3, 6].map((n) {
                              return Padding(
                                padding: EdgeInsets.zero,
                                child: ActionChip(
                                  label: Text(n == 6 ? 'Half sem (6)' : '$n month${n == 1 ? '' : 's'}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11, fontWeight: FontWeight.w700)),
                                  avatar: const Icon(Icons.bolt_rounded, size: 14),
                                  backgroundColor: ChefColors.primarySoft,
                                  side: BorderSide.none,
                                  onPressed: () => setDialogState(() {
                                    selectPlan(n);
                                    amountController.text = '${defaultTotal(n)}';
                                    duplicateWarning = '';
                                  }),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),

                          // Month cards (tap to select / unselect)
                          LayoutBuilder(builder: (context, box) {
                            final cols = box.maxWidth < 340 ? 3 : box.maxWidth < 470 ? 4 : 5;
                            final cardW = ((box.maxWidth - 6 * (cols - 1)) / cols).floorToDouble();
                            return Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: dialogMonths.map((mName) {
                              final paid = isPaid(mName);
                              final isSel = selected.contains(mName);
                              return SizedBox(
                                width: cardW,
                                child: _buildCompactMonthCard(
                                  monthName: mName,
                                  isSelected: isSel,
                                  isPaid: paid,
                                  onTap: () {
                                    setDialogState(() {
                                      if (isSel) {
                                        selected.remove(mName);
                                      } else {
                                        selected.add(mName);
                                      }
                                      final now = sortedSelected();
                                      amountController.text = '${defaultTotal(now.length)}';
                                      utrController.text = now.length == 1
                                          ? (_utrFor(userPaidSet, now.first) ?? '')
                                          : utrController.text;
                                      duplicateWarning = '';
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          );
                          }),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ChefColors.border),
                            ),
                            child: Text(
                              months.isEmpty
                                  ? 'Select at least one month.'
                                  : '${months.length} month${months.length == 1 ? '' : 's'} selected: ${months.join(', ')}\nTotal ₹${total.toStringAsFixed(0)} (₹${perMonth.toStringAsFixed(0)}/month) · access till end of ${months.last}',
                              style: GoogleFonts.poppins(fontSize: 11, color: ChefColors.text, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionTitle('Payment details', Icons.payments_outlined),
                          const SizedBox(height: 8),
                          _fieldPair(
                            isPhone,
                            flexA: 4,
                            flexB: 6,
                            a: SizedBox(
                                  height: 46,
                                  child: TextField(
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setDialogState(() {}),
                                    style: GoogleFonts.poppins(fontSize: 12.5),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: 'Total amount (₹)',
                                      prefixIcon: Icon(Icons.currency_rupee_rounded, size: 16),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                    ),
                                  ),
                                ),
                            b: SizedBox(
                                  height: 46,
                                  child: TextField(
                                    controller: utrController,
                                    style: GoogleFonts.poppins(fontSize: 12.5),
                                    onChanged: (val) {
                                      final trimmed = val.trim();
                                      if (_isRealUtrNumber(trimmed)) {
                                        String foundInMonth = '';
                                        bool foundDuplicate = false;
                                        _userPaymentMap.forEach((uId, mData) {
                                          if (uId != student.id) {
                                            mData.forEach((m, txn) {
                                              if (_isRealUtrNumber(txn) &&
                                                  txn.trim().toLowerCase() == trimmed.toLowerCase()) {
                                                foundDuplicate = true;
                                                foundInMonth = m;
                                              }
                                            });
                                          }
                                        });
                                        setDialogState(() {
                                          duplicateWarning = foundDuplicate
                                              ? 'Warning: This UTR was already recorded for another student in $foundInMonth.'
                                              : '';
                                        });
                                      } else {
                                        setDialogState(() => duplicateWarning = '');
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: 'UTR / Txn ID *',
                                      prefixIcon: Icon(Icons.confirmation_number_outlined, size: 16),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                    ),
                                  ),
                                ),
                          ),
                          if (duplicateWarning.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: ChefColors.dangerSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ChefColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: ChefColors.danger, size: 15),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(duplicateWarning,
                                        style: GoogleFonts.poppins(
                                            color: ChefColors.danger,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _fieldPair(
                            isPhone,
                            a: SizedBox(
                                  height: 46,
                                  child: TextField(
                                    controller: fatherPhoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.poppins(fontSize: 12.5),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: "Father's Phone",
                                      prefixIcon: Icon(Icons.family_restroom_outlined, size: 16),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                    ),
                                  ),
                                ),
                            b: SizedBox(
                                  height: 46,
                                  child: TextField(
                                    controller: dateController,
                                    style: GoogleFonts.poppins(fontSize: 12.5),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: 'Date (YYYY-MM-DD)',
                                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---------- Save ----------
                  Container(
                    padding: EdgeInsets.fromLTRB(isPhone ? 14 : 18, 10, isPhone ? 14 : 18, 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: ChefColors.border)),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: months.isEmpty
                            ? null
                            : () async {
                                if (utrController.text.trim().isEmpty) {
                                  Get.snackbar(
                                    'UTR missing',
                                    'Please enter a UTR or receipt ID.',
                                    backgroundColor: ChefColors.danger,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                    margin: const EdgeInsets.all(12),
                                  );
                                  return;
                                }

                                try {
                                  final res = await http.post(
                                    Uri.parse(ApiEndpoints.adminManualPayment),
                                    headers: {'Content-Type': 'application/json'},
                                    body: jsonEncode({
                                      'userId': student.id,
                                      'amount': perMonth,
                                      'paymentsData': months
                                          .map((m) => {
                                                'month': m,
                                                'transactionId': utrController.text.trim(),
                                              })
                                          .toList(),
                                      'fatherPhone': fatherPhoneController.text.trim(),
                                      'paymentDate': dateController.text.trim(),
                                    }),
                                  );

                                  final resData = json.decode(res.body);

                                  if (res.statusCode == 200) {
                                    Navigator.of(dialogContext).pop();
                                    await _loadAllData();
                                    Get.snackbar(
                                      'Payment updated',
                                      'Saved ${months.length} month${months.length == 1 ? '' : 's'} (${months.first}${months.length > 1 ? ' – ${months.last}' : ''}) and access granted.',
                                      backgroundColor: ChefColors.success,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                      margin: const EdgeInsets.all(12),
                                    );
                                  } else {
                                    Get.snackbar(
                                      'Payment Rejected',
                                      resData['message'] ?? 'The payment could not be recorded.',
                                      backgroundColor: ChefColors.danger,
                                      colorText: Colors.white,
                                      duration: const Duration(seconds: 4),
                                      snackPosition: SnackPosition.BOTTOM,
                                      margin: const EdgeInsets.all(12),
                                    );
                                  }
                                } catch (e) {
                                  Get.snackbar(
                                    'Connection error',
                                    'Please check the server connection and try again.',
                                    backgroundColor: ChefColors.danger,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                    margin: const EdgeInsets.all(12),
                                  );
                                }
                              },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          months.isEmpty
                              ? 'Select month(s)'
                              : months.length == 1
                                  ? (isPhone ? 'Save ${months.first.split(' ').first} & approve' : 'Save ${months.first} payment & approve')
                                  : 'Save ${months.length} months & approve',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChefColors.primary,
                          foregroundColor: const Color(0xFF241C00),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Two fields side by side on web / tablet, one under the other on phone.
  Widget _fieldPair(bool stack, {required Widget a, required Widget b, int flexA = 1, int flexB = 1}) {
    if (stack) {
      return Column(children: [a, const SizedBox(height: 8), b]);
    }
    return Row(
      children: [
        Expanded(flex: flexA, child: a),
        const SizedBox(width: 8),
        Expanded(flex: flexB, child: b),
      ],
    );
  }

  Widget _buildCompactMonthCard({
    required String monthName,
    required bool isSelected,
    required bool isPaid,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color borderColor;

    if (isSelected) {
      bgColor = const Color(0xFFFFF9E6);
      borderColor = const Color(0xFFF59E0B);
    } else if (isPaid) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
    } else {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
    }

    final parts = monthName.split(' ');
    final shortName = parts.first.length > 3 ? parts.first.substring(0, 3) : parts.first;
    final year = parts.length > 1 ? parts[1] : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected || isPaid ? 1.4 : 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF59E0B)
                          : (isPaid ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'DUE',
                    style: GoogleFonts.poppins(
                      color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(shortName,
                maxLines: 1,
                style: GoogleFonts.poppins(
                    color: ChefColors.text, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(year,
                style: GoogleFonts.poppins(
                    color: ChefColors.muted, fontSize: 9.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: ChefColors.primaryDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: ChefColors.text,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Future<void> _exportExcel() async {
    final group = _tabController.index == 0 ? 'Junior' : 'Senior';

    String backendGender = 'All';
    if (selectedFilterCategory.contains('Boy')) {
      backendGender = 'Male';
    } else if (selectedFilterCategory.contains('Girl')) {
      backendGender = 'Female';
    }

    final urlString =
        '${ApiEndpoints.adminExportExcel}?yearGroup=$group&gender=${Uri.encodeComponent(backendGender)}&month=${Uri.encodeComponent(selectedMonth)}&unpaidOnly=$showUnpaidOnly';

    Get.snackbar(
      'Exporting Excel',
      showUnpaidOnly
          ? 'Generating unpaid students report...'
          : 'Generating mess report...',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );

    try {
      final response = await http.get(
        Uri.parse(urlString),
        headers: {'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}'},
      );

      if (response.statusCode == 200) {
        final cleanMonth = selectedMonth.replaceAll(' ', '_');
        final prefix = showUnpaidOnly ? 'UNPAID_' : '';
        final cleanCategory = selectedFilterCategory.replaceAll(' ', '_');
        final filename =
            'Chef_${prefix}Mess_Report_${group}_${cleanCategory}_$cleanMonth.xlsx';

        if (kIsWeb) {
          // 🌐 Web: download through the browser (same as before)
          final blob = html.Blob([
            response.bodyBytes,
          ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);

          final anchor = html.AnchorElement(href: blobUrl)
            ..setAttribute('download', filename)
            ..style.display = 'none';

          html.document.body?.children.add(anchor);
          anchor.click();

          anchor.remove();
          html.Url.revokeObjectUrl(blobUrl);
        } else {
          // 📱 Android / iOS: save the file and open it
          final dir = await getApplicationDocumentsDirectory();
          final file = io.File('${dir.path}/$filename');
          await file.writeAsBytes(response.bodyBytes, flush: true);
          await OpenFilex.open(file.path);
        }

        Get.snackbar(
          'Download Complete',
          '$filename saved successfully.',
          backgroundColor: ChefColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
      } else {
        Get.snackbar(
          'Download Failed',
          'Server returned code ${response.statusCode}',
          backgroundColor: ChefColors.danger,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (e) {
      debugPrint('Excel export error: $e');
      Get.snackbar(
        'Download Failed',
        'Could not complete file download: $e',
        backgroundColor: ChefColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Widget _buildExcelExportButton() {
    return OutlinedButton.icon(
      onPressed: _exportExcel,
      icon: Icon(
        showUnpaidOnly
            ? Icons.warning_amber_rounded
            : Icons.file_download_outlined,
        size: 17,
      ),
      label: Text(
        showUnpaidOnly ? 'Unpaid Excel' : 'Export Excel',
        style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A1A1A),
        side: const BorderSide(color: Color(0xFF1A1A1A)),
        backgroundColor: showUnpaidOnly
            ? ChefColors.dangerSoft
            : const Color(0xFFF9FAFC),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }
}