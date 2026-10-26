// import 'dart:convert';
// import 'dart:html' as html;
// import 'package:ami_admin/controllers/updateing_user_status_controller.dart';
// import 'package:ami_admin/screens/payment_notice_banner.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;

// import '../apis/apis_localhost.dart';
// import '../models/user_models.dart';

// class ChefColors {
//   static const primary = Color(0xFFFFC800);
//   static const primaryDark = Color(0xFF9A7600);
//   static const primarySoft = Color(0xFFFFF6CC);

//   static const background = Color(0xFFF6F8FC);
//   static const surface = Colors.white;
//   static const border = Color(0xFFE5EAF2);

//   static const text = Color(0xFF172033);
//   static const muted = Color(0xFF667085);

//   static const success = Color(0xFF16A34A);
//   static const successSoft = Color(0xFFEAF8EF);
//   static const danger = Color(0xFFDC2626);
//   static const dangerSoft = Color(0xFFFFEEEE);
//   static const warning = Color(0xFFF59E0B);
//   static const warningSoft = Color(0xFFFFF7E6);
// }

// class _MetricData {
//   final String title;
//   final String count;
//   final IconData icon;
//   final Color iconBackground;
//   final Color iconColor;

//   const _MetricData({
//     required this.title,
//     required this.count,
//     required this.icon,
//     required this.iconBackground,
//     required this.iconColor,
//   });
// }

// class StudentFinancialScreen extends StatefulWidget {
//   const StudentFinancialScreen({super.key});

//   @override
//   State<StudentFinancialScreen> createState() => _StudentFinancialScreenState();
// }

// class _StudentFinancialScreenState extends State<StudentFinancialScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   final AdminController adminController = Get.put(AdminController());

//   // Comprehensive filter categories requested by client
//   String selectedFilterCategory = 'All';
//   String selectedMonth = 'October 2026';
//   bool showUnpaidOnly = false;

//   final Set<String> _currentMonthPaidUserIds = {};
//   final Map<String, Map<String, String>> _userPaymentMap = {};
//   bool _isLoadingPayments = false;

//   static const List<String> _filterCategories = [
//     'All',
//     'All Boys',
//     'Junior Boys',
//     'Senior Boys',
//     'All Girls',
//     'Junior Girls',
//     'Senior Girls',
//   ];

//   static const List<String> _monthNames = [
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December',
//   ];

//   List<String> get monthsList {
//     final now = DateTime.now();
//     final cur = '${_monthNames[now.month - 1]} ${now.year}';
//     return [
//       'All Year',
//       'August 2026',
//       'September 2026',
//       'October 2026',
//       if (!cur.contains('August') &&
//           !cur.contains('September') &&
//           !cur.contains('October'))
//         cur,
//     ].toSet().toList();
//   }

//   bool _isRealUtrNumber(String val) {
//     final clean = val.trim().toLowerCase();
//     if (clean.isEmpty ||
//         clean == 'unpaid' ||
//         clean == 'pending' ||
//         clean == 'due' ||
//         clean == 'none' ||
//         clean == 'null' ||
//         clean == 'n/a' ||
//         clean == 'na' ||
//         clean.startsWith('cash')) {
//       return false;
//     }
//     final digitsOnly = clean.replaceAll(RegExp(r'\D'), '');
//     return digitsOnly.length >= 6;
//   }

//   bool _isJunior(AppUser u) => u.year == '1' || u.year.contains('1');
//   bool _isBoy(AppUser u) => u.gender.trim().toLowerCase() == 'male';
//   bool _isGirl(AppUser u) => u.gender.trim().toLowerCase() == 'female';

//   bool _matchesSelectedCategory(AppUser u) {
//     switch (selectedFilterCategory) {
//       case 'All Boys':
//         return _isBoy(u);
//       case 'Junior Boys':
//         return _isBoy(u) && _isJunior(u);
//       case 'Senior Boys':
//         return _isBoy(u) && !_isJunior(u);
//       case 'All Girls':
//         return _isGirl(u);
//       case 'Junior Girls':
//         return _isGirl(u) && _isJunior(u);
//       case 'Senior Girls':
//         return _isGirl(u) && !_isJunior(u);
//       case 'All':
//       default:
//         return true;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);

//     final now = DateTime.now();
//     selectedMonth = '${_monthNames[now.month - 1]} ${now.year}';

//     _loadAllData();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadAllData() async {
//     adminController.fetchUsers();
//     await _fetchGlobalPayments();
//   }

//   Future<void> _fetchGlobalPayments() async {
//     try {
//       setState(() => _isLoadingPayments = true);
//       final response = await http.get(
//         Uri.parse('${ApiEndpoints.adminAllPayments}?month=All Year'),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List payments = (data is List) ? data : (data['payments'] ?? []);

//         _userPaymentMap.clear();

//         for (var p in payments) {
//           final status = (p['status'] ?? '').toString().trim().toLowerCase();
//           final amount = num.tryParse((p['amount'] ?? 0).toString()) ?? 0;
//           final mName = (p['month'] ?? '').toString().trim();
//           final txn = (p['transactionId'] ?? '').toString().trim();

//           if ((status == 'success' ||
//                   (txn.isNotEmpty &&
//                       txn.toLowerCase() != 'unpaid' &&
//                       txn != 'N/A' &&
//                       txn != 'n/a')) &&
//               amount > 0) {
//             String uid = '';
//             if (p['userId'] is Map) {
//               uid = (p['userId']['_id'] ?? p['userId']['id'] ?? '').toString();
//             } else {
//               uid = (p['userId'] ?? '').toString();
//             }

//             if (uid.isNotEmpty) {
//               _userPaymentMap.putIfAbsent(uid, () => {})[mName.toLowerCase()] =
//                   txn;
//             }
//           }
//         }

//         _recalculateCurrentMonthPaidSet();
//       }
//     } catch (e) {
//       debugPrint('Error loading payments: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoadingPayments = false);
//       }
//     }
//   }

//   void _recalculateCurrentMonthPaidSet() {
//     _currentMonthPaidUserIds.clear();
//     final target = selectedMonth.toLowerCase().trim();
//     final isAllYear = (target == 'all year');
//     final targetPrefix = target.split(' ')[0];

//     _userPaymentMap.forEach((uid, monthMap) {
//       if (isAllYear) {
//         final hasAug = monthMap.keys.any((k) => k.contains('august'));
//         final hasSep = monthMap.keys.any((k) => k.contains('september'));
//         final hasOct = monthMap.keys.any((k) => k.contains('october'));
//         if (hasAug && hasSep && hasOct) {
//           _currentMonthPaidUserIds.add(uid);
//         }
//       } else {
//         if (monthMap.keys.any((k) => k.contains(targetPrefix))) {
//           _currentMonthPaidUserIds.add(uid);
//         }
//       }
//     });
//   }

//   Future<void> _confirmDeleteStudent(AppUser student) async {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             const Icon(Icons.warning_amber_rounded, color: ChefColors.danger),
//             const SizedBox(width: 8),
//             Text(
//               'Delete Student',
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           'Are you sure you want to permanently delete "${student.name}" (Room: ${student.room})? This action cannot be undone.',
//           style: GoogleFonts.poppins(fontSize: 13, color: ChefColors.text),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: Text(
//               'Cancel',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w600,
//                 color: ChefColors.muted,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Get.back();
//               try {
//                 final res = await http.delete(
//                   Uri.parse('${ApiEndpoints.adminUsers}/${student.id}'),
//                   headers: {
//                     'Content-Type': 'application/json',
//                     'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}',
//                   },
//                 );

//                 if (res.statusCode == 200) {
//                   await _loadAllData();
//                   Get.snackbar(
//                     'Student Deleted',
//                     '${student.name} has been removed from the mess database.',
//                     backgroundColor: ChefColors.danger,
//                     colorText: Colors.white,
//                     snackPosition: SnackPosition.BOTTOM,
//                     margin: const EdgeInsets.all(12),
//                   );
//                 } else {
//                   Get.snackbar(
//                     'Delete Failed',
//                     'Could not delete student (${res.statusCode})',
//                     backgroundColor: ChefColors.danger,
//                     colorText: Colors.white,
//                   );
//                 }
//               } catch (e) {
//                 Get.snackbar(
//                   'Error',
//                   'Network error deleting student: $e',
//                   backgroundColor: ChefColors.danger,
//                   colorText: Colors.white,
//                 );
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: ChefColors.danger,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text(
//               'Delete',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: Theme.of(context).copyWith(
//         scaffoldBackgroundColor: ChefColors.background,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: ChefColors.primary,
//           brightness: Brightness.light,
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           filled: true,
//           fillColor: const Color(0xFFF9FAFC),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 14,
//             vertical: 13,
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(13),
//             borderSide: const BorderSide(color: ChefColors.border),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(13),
//             borderSide: const BorderSide(color: ChefColors.border),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(13),
//             borderSide: const BorderSide(color: ChefColors.primary, width: 1.5),
//           ),
//           labelStyle: const TextStyle(color: ChefColors.muted),
//           hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
//         ),
//       ),
//       // ⚠️ First tap anywhere shows the payment notice; screen unlocks after "I understand".
//       child: PaymentNoticeGate(
//         child: Scaffold(
//         backgroundColor: ChefColors.background,
//         appBar: _buildAppBar(),
//         body: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final width = constraints.maxWidth;
//               final isMobile = width < 650;
//               final isTablet = width >= 650 && width < 1050;

//               return Center(
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 1500),
//                   child: Column(
//                     children: [
//                       // --- ⚠️ PAYMENT / SERVER NOTICE ---
//                       Padding(
//                         padding: EdgeInsets.fromLTRB(
//                           isMobile ? 12 : 28,
//                           8,
//                           isMobile ? 12 : 28,
//                           0,
//                         ),
//                         child: const PaymentNoticeBanner(),
//                       ),
//                       _buildMetricsSummaryBar(isMobile),
//                       _buildFilterToolbar(isMobile, isTablet),
//                       _buildTabs(isMobile),
//                       Expanded(
//                         child: TabBarView(
//                           controller: _tabController,
//                           children: [
//                             _buildStudentListView(
//                               isJunior: true,
//                               isCompact: isMobile,
//                             ),
//                             _buildStudentListView(
//                               isJunior: false,
//                               isCompact: isMobile,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: ChefColors.primary,
//       surfaceTintColor: ChefColors.primary,
//       elevation: 0,
//       scrolledUnderElevation: 0,
//       automaticallyImplyLeading: false,
//       toolbarHeight: 56,
//       titleSpacing: 0,
//       leadingWidth: 44,
//       leading: IconButton(
//         tooltip: 'Back',
//         padding: EdgeInsets.zero,
//         onPressed: () {
//           if (Navigator.of(context).canPop()) {
//             Navigator.of(context).pop();
//           } else if (Get.key.currentState?.canPop() == true) {
//             Get.back();
//           }
//         },
//         icon: const Icon(
//           Icons.arrow_back_ios_new_rounded,
//           color: Color(0xFF1A1A1A),
//           size: 18,
//         ),
//       ),
//       title: Padding(
//         padding: const EdgeInsets.only(left: 4),
//         child: Text(
//           'Student Finance',
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: GoogleFonts.poppins(
//             color: const Color(0xFF1A1A1A),
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//             letterSpacing: -0.3,
//           ),
//         ),
//       ),
//       actions: [
//         IconButton(
//           tooltip: 'Refresh',
//           onPressed: _loadAllData,
//           icon: const Icon(
//             Icons.refresh_rounded,
//             color: Color(0xFF1A1A1A),
//             size: 21,
//           ),
//         ),
//         Builder(
//           builder: (context) {
//             final mobile = MediaQuery.sizeOf(context).width < 650;

//             if (mobile) {
//               return Padding(
//                 padding: const EdgeInsets.only(right: 6),
//                 child: IconButton(
//                   tooltip: 'Export Excel',
//                   onPressed: () => _exportExcel(),
//                   icon: Icon(
//                     showUnpaidOnly
//                         ? Icons.warning_amber_rounded
//                         : Icons.file_download_outlined,
//                     color: const Color(0xFF1A1A1A),
//                     size: 21,
//                   ),
//                 ),
//               );
//             }

//             return Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: _buildExcelExportButton(),
//             );
//           },
//         ),
//       ],
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(
//           height: 1,
//           color: ChefColors.primaryDark.withValues(alpha: 0.18),
//         ),
//       ),
//     );
//   }

//   Widget _buildTabs(bool isCompact) {
//     return Container(
//       margin: EdgeInsets.fromLTRB(
//         isCompact ? 12 : 28,
//         7,
//         isCompact ? 12 : 28,
//         7,
//       ),
//       padding: const EdgeInsets.all(3),
//       decoration: BoxDecoration(
//         color: const Color(0xFFEFF2F6),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFE4E8EE)),
//       ),
//       child: SizedBox(
//         height: isCompact ? 42 : 44,
//         child: TabBar(
//           controller: _tabController,
//           dividerColor: Colors.transparent,
//           indicatorSize: TabBarIndicatorSize.tab,
//           indicator: BoxDecoration(
//             color: ChefColors.primary,
//             borderRadius: BorderRadius.circular(11),
//             boxShadow: const [
//               BoxShadow(
//                 color: Color(0x16000000),
//                 blurRadius: 8,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           labelColor: const Color(0xFF211B00),
//           unselectedLabelColor: ChefColors.muted,
//           labelStyle: GoogleFonts.poppins(
//             fontSize: isCompact ? 10.5 : 11.5,
//             fontWeight: FontWeight.w800,
//           ),
//           unselectedLabelStyle: GoogleFonts.poppins(
//             fontSize: isCompact ? 10.5 : 11.5,
//             fontWeight: FontWeight.w600,
//           ),
//           tabs: const [
//             Tab(text: 'Juniors · 1st Year'),
//             Tab(text: 'Seniors · 2nd–5th Year'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMetricsSummaryBar(bool isCompact) {
//     return Obx(() {
//       final allUsers = adminController.filteredUsers;
//       final selectedCohort = allUsers.where(_matchesSelectedCategory).toList();

//       final totalCount = selectedCohort.length;
//       final activeCount = selectedCohort
//           .where((u) => _currentMonthPaidUserIds.contains(u.id))
//           .length;
//       final noAccessCount = totalCount - activeCount;

//       final categoryLabel = selectedFilterCategory == 'All'
//           ? 'Total Students'
//           : selectedFilterCategory;

//       final cards = [
//         _MetricData(
//           title: categoryLabel,
//           count: totalCount.toString(),
//           icon: Icons.groups_rounded,
//           iconBackground: ChefColors.primarySoft,
//           iconColor: ChefColors.primaryDark,
//         ),
//         _MetricData(
//           title: 'Paid',
//           count: activeCount.toString(),
//           icon: Icons.verified_rounded,
//           iconBackground: ChefColors.successSoft,
//           iconColor: ChefColors.success,
//         ),
//         _MetricData(
//           title: 'Pending',
//           count: noAccessCount.toString(),
//           icon: Icons.priority_high_rounded,
//           iconBackground: ChefColors.warningSoft,
//           iconColor: ChefColors.warning,
//         ),
//       ];

//       if (isCompact) {
//         return SizedBox(
//           height: 70,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
//             itemCount: cards.length,
//             separatorBuilder: (_, __) => const SizedBox(width: 8),
//             itemBuilder: (_, index) => SizedBox(
//               width: 154,
//               child: _buildMetricCard(
//                 title: cards[index].title,
//                 count: cards[index].count,
//                 icon: cards[index].icon,
//                 iconBackground: cards[index].iconBackground,
//                 iconColor: cards[index].iconColor,
//               ),
//             ),
//           ),
//         );
//       }

//       return Padding(
//         padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
//         child: Row(
//           children: [
//             for (var i = 0; i < cards.length; i++) ...[
//               if (i > 0) const SizedBox(width: 8),
//               Expanded(
//                 child: _buildMetricCard(
//                   title: cards[i].title,
//                   count: cards[i].count,
//                   icon: cards[i].icon,
//                   iconBackground: cards[i].iconBackground,
//                   iconColor: cards[i].iconColor,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildMetricCard({
//     required String title,
//     required String count,
//     required IconData icon,
//     required Color iconBackground,
//     required Color iconColor,
//   }) {
//     return Container(
//       height: 60,
//       padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: ChefColors.border),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x05000000),
//             blurRadius: 10,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(
//               color: iconBackground,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: iconColor, size: 17),
//           ),
//           const SizedBox(width: 9),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: GoogleFonts.poppins(
//                     color: ChefColors.muted,
//                     fontSize: 9.5,
//                     fontWeight: FontWeight.w700,
//                     height: 1,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   count,
//                   maxLines: 1,
//                   style: GoogleFonts.poppins(
//                     color: ChefColors.text,
//                     fontSize: 19,
//                     fontWeight: FontWeight.w800,
//                     height: 1,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterToolbar(bool isMobile, bool isTablet) {
//     if (isMobile) {
//       return Container(
//         margin: const EdgeInsets.fromLTRB(12, 3, 12, 2),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(17),
//           border: Border.all(color: ChefColors.border),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x04000000),
//               blurRadius: 10,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             SizedBox(
//               height: 47,
//               child: TextField(
//                 onChanged: adminController.updateSearchQuery,
//                 style: GoogleFonts.poppins(
//                   fontSize: 12.5,
//                   color: ChefColors.text,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 decoration: InputDecoration(
//                   hintText: 'Search students...',
//                   prefixIcon: const Icon(
//                     Icons.search_rounded,
//                     color: ChefColors.primaryDark,
//                     size: 21,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 10,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(13),
//                     borderSide: const BorderSide(color: ChefColors.border),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(13),
//                     borderSide: const BorderSide(color: ChefColors.border),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(13),
//                     borderSide: const BorderSide(
//                       color: ChefColors.primary,
//                       width: 1.4,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildFilterDropdown(
//                     value: selectedFilterCategory,
//                     icon: Icons.filter_alt_outlined,
//                     items: _filterCategories,
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() {
//                           selectedFilterCategory = value;
//                           if (value.contains('Junior') &&
//                               _tabController.index != 0) {
//                             _tabController.animateTo(0);
//                           } else if (value.contains('Senior') &&
//                               _tabController.index != 1) {
//                             _tabController.animateTo(1);
//                           }
//                         });
//                       }
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   flex: 1,
//                   child: _buildFilterDropdown(
//                     value: selectedMonth,
//                     icon: Icons.calendar_month_outlined,
//                     items: monthsList,
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() {
//                           selectedMonth = value;
//                           _recalculateCurrentMonthPaidSet();
//                         });
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 5),
//             Align(alignment: Alignment.centerLeft, child: _buildUnpaidFilter()),
//           ],
//         ),
//       );
//     }

//     return Container(
//       margin: EdgeInsets.fromLTRB(isTablet ? 18 : 28, 8, isTablet ? 18 : 28, 0),
//       padding: const EdgeInsets.all(9),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: ChefColors.border),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x04000000),
//             blurRadius: 12,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               onChanged: adminController.updateSearchQuery,
//               style: GoogleFonts.poppins(
//                 fontSize: 12,
//                 color: ChefColors.text,
//                 fontWeight: FontWeight.w500,
//               ),
//               decoration: const InputDecoration(
//                 hintText: 'Search name, phone or student ID',
//                 prefixIcon: Icon(
//                   Icons.search_rounded,
//                   color: ChefColors.primaryDark,
//                   size: 20,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 9),
//           SizedBox(
//             width: isTablet ? 165 : 185,
//             child: _buildFilterDropdown(
//               value: selectedFilterCategory,
//               icon: Icons.filter_alt_outlined,
//               items: _filterCategories,
//               onChanged: (value) {
//                 if (value != null) {
//                   setState(() {
//                     selectedFilterCategory = value;
//                     if (value.contains('Junior') && _tabController.index != 0) {
//                       _tabController.animateTo(0);
//                     } else if (value.contains('Senior') &&
//                         _tabController.index != 1) {
//                       _tabController.animateTo(1);
//                     }
//                   });
//                 }
//               },
//             ),
//           ),
//           const SizedBox(width: 9),
//           SizedBox(
//             width: isTablet ? 155 : 175,
//             child: _buildFilterDropdown(
//               value: selectedMonth,
//               icon: Icons.calendar_month_outlined,
//               items: monthsList,
//               onChanged: (value) {
//                 if (value != null) {
//                   setState(() {
//                     selectedMonth = value;
//                     _recalculateCurrentMonthPaidSet();
//                   });
//                 }
//               },
//             ),
//           ),
//           const SizedBox(width: 9),
//           _buildUnpaidFilter(),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterDropdown({
//     required String value,
//     required IconData icon,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//   }) {
//     final effectiveValue = items.contains(value) ? value : items.first;

//     return SizedBox(
//       height: 45,
//       child: DropdownButtonFormField<String>(
//         value: effectiveValue,
//         isExpanded: true,
//         icon: const Icon(
//           Icons.keyboard_arrow_down_rounded,
//           color: ChefColors.muted,
//           size: 19,
//         ),
//         decoration: InputDecoration(
//           filled: true,
//           fillColor: const Color(0xFFF9FAFC),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 9,
//             vertical: 0,
//           ),
//           prefixIcon: Icon(icon, size: 17, color: ChefColors.primaryDark),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: ChefColors.border),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: ChefColors.border),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: ChefColors.primary, width: 1.3),
//           ),
//         ),
//         style: GoogleFonts.poppins(
//           color: ChefColors.text,
//           fontSize: 11.5,
//           fontWeight: FontWeight.w600,
//         ),
//         items: items
//             .map(
//               (item) => DropdownMenuItem(
//                 value: item,
//                 child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
//               ),
//             )
//             .toList(),
//         onChanged: onChanged,
//       ),
//     );
//   }

//   Widget _buildUnpaidFilter() {
//     return FilterChip(
//       selected: showUnpaidOnly,
//       showCheckmark: false,
//       avatar: Icon(
//         showUnpaidOnly
//             ? Icons.check_circle_rounded
//             : Icons.error_outline_rounded,
//         size: 16,
//         color: showUnpaidOnly ? const Color(0xFF8A6800) : ChefColors.muted,
//       ),
//       label: const Text('Unpaid only'),
//       selectedColor: ChefColors.primarySoft,
//       backgroundColor: const Color(0xFFF9FAFC),
//       side: BorderSide(
//         color: showUnpaidOnly ? ChefColors.primary : ChefColors.border,
//       ),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
//       labelStyle: GoogleFonts.poppins(
//         color: showUnpaidOnly ? const Color(0xFF6B5200) : ChefColors.text,
//         fontSize: 10.5,
//         fontWeight: FontWeight.w700,
//       ),
//       onSelected: (value) => setState(() => showUnpaidOnly = value),
//     );
//   }

//   Widget _buildStudentListView({
//     required bool isJunior,
//     required bool isCompact,
//   }) {
//     return Obx(() {
//       if (adminController.isLoading.value || _isLoadingPayments) {
//         return const Center(
//           child: CircularProgressIndicator(
//             color: ChefColors.primary,
//             strokeWidth: 2.5,
//           ),
//         );
//       }

//       final filtered = adminController.filteredUsers.where((u) {
//         final matchesYear = isJunior ? _isJunior(u) : !_isJunior(u);
//         final matchesCategory = _matchesSelectedCategory(u);
//         final isPaid = _currentMonthPaidUserIds.contains(u.id);
//         final matchesUnpaid = !showUnpaidOnly || !isPaid;

//         return matchesYear && matchesCategory && matchesUnpaid;
//       }).toList();

//       if (filtered.isEmpty) return _buildEmptyState();

//       filtered.sort((a, b) {
//         return a.name.trim().toLowerCase().compareTo(
//           b.name.trim().toLowerCase(),
//         );
//       });

//       return ListView.builder(
//         physics: const BouncingScrollPhysics(),
//         padding: EdgeInsets.fromLTRB(
//           isCompact ? 12 : 28,
//           5,
//           isCompact ? 12 : 28,
//           24,
//         ),
//         itemCount: filtered.length,
//         itemBuilder: (context, index) {
//           final student = filtered[index];
//           final isPaid = _currentMonthPaidUserIds.contains(student.id);

//           final String currentLetter = student.name.trim().isNotEmpty
//               ? student.name.trim()[0].toUpperCase()
//               : '#';

//           bool showHeader = false;
//           if (index == 0) {
//             showHeader = true;
//           } else {
//             final prevStudent = filtered[index - 1];
//             final String prevLetter = prevStudent.name.trim().isNotEmpty
//                 ? prevStudent.name.trim()[0].toUpperCase()
//                 : '#';
//             if (currentLetter != prevLetter) {
//               showHeader = true;
//             }
//           }

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (showHeader) _buildLetterHeader(currentLetter, isCompact),
//               _buildStudentCard(student, isPaid: isPaid, isCompact: isCompact),
//               const SizedBox(height: 9),
//             ],
//           );
//         },
//       );
//     });
//   }

//   Widget _buildLetterHeader(String letter, bool isCompact) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
//             decoration: BoxDecoration(
//               color: ChefColors.primary,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Color(0x14000000),
//                   blurRadius: 4,
//                   offset: Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Text(
//               letter,
//               style: GoogleFonts.poppins(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w800,
//                 color: const Color(0xFF1A1A1A),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(child: Container(height: 1, color: ChefColors.border)),
//         ],
//       ),
//     );
//   }

//   Widget _buildStudentCard(
//     AppUser student, {
//     required bool isPaid,
//     required bool isCompact,
//   }) {
//     final initial = student.name.trim().isNotEmpty
//         ? student.name.trim()[0].toUpperCase()
//         : '?';

//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(17),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(17),
//         onTap: () => _showManualPaymentDialog(student),
//         child: Container(
//           padding: EdgeInsets.all(isCompact ? 12 : 15),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(17),
//             border: Border.all(
//               color: isPaid ? const Color(0xFFE3E9E7) : const Color(0xFFE9E6DF),
//             ),
//             boxShadow: const [
//               BoxShadow(
//                 color: Color(0x05000000),
//                 blurRadius: 14,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: isCompact
//               ? _buildCompactStudentContent(student, initial, isPaid)
//               : _buildDesktopStudentContent(student, initial, isPaid),
//         ),
//       ),
//     );
//   }

//   Widget _buildDesktopStudentContent(
//     AppUser student,
//     String initial,
//     bool isPaid,
//   ) {
//     return Row(
//       children: [
//         _buildAvatar(initial, isPaid),
//         const SizedBox(width: 13),
//         Expanded(child: _buildStudentDetails(student, isPaid)),
//         const SizedBox(width: 14),
//         _buildStudentActions(student, isPaid),
//       ],
//     );
//   }

//   Widget _buildCompactStudentContent(
//     AppUser student,
//     String initial,
//     bool isPaid,
//   ) {
//     return Column(
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildAvatar(initial, isPaid),
//             const SizedBox(width: 11),
//             Expanded(child: _buildStudentDetails(student, isPaid)),
//           ],
//         ),
//         const SizedBox(height: 11),
//         Row(
//           children: [
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: () => _showManualPaymentDialog(student),
//                 icon: const Icon(Icons.receipt_long_rounded, size: 16),
//                 label: const Text('Payment'),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: ChefColors.primaryDark,
//                   side: const BorderSide(color: ChefColors.primary, width: 1.2),
//                   minimumSize: const Size(0, 40),
//                   padding: EdgeInsets.zero,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(11),
//                   ),
//                   textStyle: GoogleFonts.poppins(
//                     fontSize: 10.5,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: () => adminController.toggleApproval(student),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isPaid
//                       ? ChefColors.dangerSoft
//                       : ChefColors.primary,
//                   foregroundColor: isPaid
//                       ? ChefColors.danger
//                       : const Color(0xFF2A2200),
//                   elevation: 0,
//                   minimumSize: const Size(0, 40),
//                   padding: EdgeInsets.zero,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(11),
//                   ),
//                 ),
//                 child: Text(
//                   isPaid ? 'Revoke' : 'Grant',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: GoogleFonts.poppins(
//                     fontSize: 10.5,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 6),
//             IconButton(
//               tooltip: 'Delete Student',
//               padding: EdgeInsets.zero,
//               constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
//               icon: const Icon(
//                 Icons.delete_outline_rounded,
//                 color: ChefColors.danger,
//                 size: 19,
//               ),
//               onPressed: () => _confirmDeleteStudent(student),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildAvatar(String initial, bool isPaid) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           width: 48,
//           height: 48,
//           decoration: BoxDecoration(
//             gradient: isPaid
//                 ? const LinearGradient(
//                     colors: [ChefColors.primarySoft, Color(0xFFFFE98A)],
//                   )
//                 : const LinearGradient(
//                     colors: [Color(0xFFF4F5F7), Color(0xFFECEEF2)],
//                   ),
//             borderRadius: BorderRadius.circular(14),
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             initial,
//             style: GoogleFonts.poppins(
//               color: isPaid ? ChefColors.primaryDark : ChefColors.muted,
//               fontSize: 18,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         Positioned(
//           right: -2,
//           bottom: -2,
//           child: Container(
//             width: 17,
//             height: 17,
//             decoration: BoxDecoration(
//               color: isPaid ? ChefColors.success : ChefColors.warning,
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white, width: 2),
//             ),
//             child: Icon(
//               isPaid ? Icons.check_rounded : Icons.schedule_rounded,
//               color: Colors.white,
//               size: 10,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStudentDetails(AppUser student, bool isPaid) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Flexible(
//               child: Text(
//                 student.name,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: GoogleFonts.poppins(
//                   color: ChefColors.text,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 6),
//             _buildStatusChip(isPaid),
//           ],
//         ),
//         const SizedBox(height: 6),
//         Wrap(
//           spacing: 10,
//           runSpacing: 5,
//           children: [
//             _infoItem(Icons.badge_outlined, student.enrollmentNo),
//             _infoItem(
//               Icons.phone_outlined,
//               student.phonenumber.isEmpty ? '—' : student.phonenumber,
//             ),
//             _infoItem(Icons.meeting_room_outlined, 'Room ${student.room}'),
//             _infoItem(Icons.person_outline_rounded, student.gender),
//             _infoItem(Icons.menu_book_outlined, student.course),
//             if (student.fatherPhone.isNotEmpty)
//               _infoItem(
//                 Icons.family_restroom_outlined,
//                 'Father: ${student.fatherPhone}',
//               ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _infoItem(IconData icon, String value) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 13, color: const Color(0xFF98A2B3)),
//         const SizedBox(width: 4),
//         Text(
//           value.isEmpty ? '—' : value,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: GoogleFonts.poppins(
//             color: ChefColors.muted,
//             fontSize: 10.5,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusChip(bool isPaid) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: isPaid ? ChefColors.successSoft : ChefColors.dangerSoft,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
//             size: 11,
//             color: isPaid ? ChefColors.success : ChefColors.danger,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             isPaid ? 'PAID' : 'UNPAID',
//             style: GoogleFonts.poppins(
//               color: isPaid ? ChefColors.success : ChefColors.danger,
//               fontSize: 8,
//               fontWeight: FontWeight.w800,
//               letterSpacing: .35,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStudentActions(AppUser student, bool isPaid) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         OutlinedButton.icon(
//           onPressed: () => _showManualPaymentDialog(student),
//           icon: const Icon(Icons.receipt_long_rounded, size: 16),
//           label: const Text('Payment'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: ChefColors.primaryDark,
//             side: const BorderSide(color: ChefColors.primary),
//             padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(11),
//             ),
//             textStyle: GoogleFonts.poppins(
//               fontSize: 10.5,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         const SizedBox(width: 7),
//         TextButton(
//           onPressed: () => adminController.toggleApproval(student),
//           style: TextButton.styleFrom(
//             foregroundColor: isPaid ? ChefColors.danger : ChefColors.success,
//             padding: const EdgeInsets.symmetric(horizontal: 9),
//             textStyle: GoogleFonts.poppins(
//               fontSize: 10.5,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           child: Text(isPaid ? 'Revoke' : 'Grant'),
//         ),
//         const SizedBox(width: 4),
//         IconButton(
//           tooltip: 'Delete Student',
//           padding: EdgeInsets.zero,
//           constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
//           icon: const Icon(
//             Icons.delete_outline_rounded,
//             color: ChefColors.danger,
//             size: 20,
//           ),
//           onPressed: () => _confirmDeleteStudent(student),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 430),
//           padding: const EdgeInsets.all(30),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: ChefColors.border),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 64,
//                 height: 64,
//                 decoration: const BoxDecoration(
//                   color: ChefColors.primarySoft,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.person_search_rounded,
//                   color: ChefColors.primaryDark,
//                   size: 29,
//                 ),
//               ),
//               const SizedBox(height: 15),
//               Text(
//                 'No students found',
//                 style: GoogleFonts.poppins(
//                   color: ChefColors.text,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 15,
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 'Try changing the search, cohort category, month or unpaid filter.',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   color: ChefColors.muted,
//                   fontSize: 11.5,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _showManualPaymentDialog(AppUser student) async {
//     final amountController = TextEditingController(text: '4000');
//     final fatherPhoneController = TextEditingController(
//       text: student.fatherPhone,
//     );
//     final dateController = TextEditingController(
//       text: DateTime.now().toIso8601String().split('T').first,
//     );
//     final utrController = TextEditingController();

//     final now = DateTime.now();
//     final realMonth = '${_monthNames[now.month - 1]} ${now.year}';
//     String selectedMonthInDialog = realMonth;

//     final dialogMonthsList = [
//       'August 2026',
//       'September 2026',
//       'October 2026',
//       if (!realMonth.contains('August') &&
//           !realMonth.contains('September') &&
//           !realMonth.contains('October'))
//         realMonth,
//     ].toSet().toList();

//     final userPaidSet = _userPaymentMap[student.id] ?? {};

//     final initialPrefix = selectedMonthInDialog.split(' ')[0].toLowerCase();
//     utrController.text = userPaidSet[initialPrefix] ?? '';

//     String duplicateWarning = '';

//     Get.dialog(
//       Dialog(
//         backgroundColor: Colors.white,
//         insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
//           child: StatefulBuilder(
//             builder: (dialogContext, setDialogState) {
//               final activePrefix = selectedMonthInDialog
//                   .split(' ')[0]
//                   .toLowerCase();
//               final isCurrentSelectedMonthPaid = userPaidSet.keys.any(
//                 (k) => k.contains(activePrefix),
//               );

//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: ChefColors.primarySoft,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Icon(
//                             Icons.receipt_long_rounded,
//                             color: ChefColors.primaryDark,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Record / Edit payment',
//                                 style: GoogleFonts.poppins(
//                                   color: ChefColors.text,
//                                   fontSize: 14.5,
//                                   fontWeight: FontWeight.w800,
//                                 ),
//                               ),
//                               Text(
//                                 student.name,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: GoogleFonts.poppins(
//                                   color: ChefColors.muted,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         IconButton(
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                           onPressed: () => Navigator.of(dialogContext).pop(),
//                           icon: const Icon(Icons.close_rounded, size: 20),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(
//                     height: 1,
//                     thickness: 1,
//                     color: ChefColors.border,
//                   ),
//                   Flexible(
//                     child: SingleChildScrollView(
//                       physics: const BouncingScrollPhysics(),
//                       padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               _sectionTitle(
//                                 'Select Month',
//                                 Icons.calendar_month_rounded,
//                               ),
//                               if (isCurrentSelectedMonthPaid)
//                                 TextButton.icon(
//                                   onPressed: () async {
//                                     try {
//                                       final res = await http.delete(
//                                         Uri.parse(
//                                           ApiEndpoints.adminDeleteMonthPayment,
//                                         ),
//                                         headers: {
//                                           'Content-Type': 'application/json',
//                                         },
//                                         body: jsonEncode({
//                                           'userId': student.id,
//                                           'month': selectedMonthInDialog,
//                                         }),
//                                       );

//                                       if (res.statusCode == 200) {
//                                         Navigator.of(dialogContext).pop();
//                                         await _loadAllData();
//                                         Get.snackbar(
//                                           'Reset Done',
//                                           '$selectedMonthInDialog has been reset to Unpaid.',
//                                           backgroundColor: ChefColors.warning,
//                                           colorText: Colors.black,
//                                           snackPosition: SnackPosition.BOTTOM,
//                                         );
//                                       } else {
//                                         Get.snackbar(
//                                           'Error',
//                                           'Could not reset month payment.',
//                                         );
//                                       }
//                                     } catch (_) {
//                                       Get.snackbar(
//                                         'Error',
//                                         'Connection error.',
//                                       );
//                                     }
//                                   },
//                                   icon: const Icon(
//                                     Icons.undo_rounded,
//                                     size: 14,
//                                     color: ChefColors.danger,
//                                   ),
//                                   label: Text(
//                                     'Reset $selectedMonthInDialog',
//                                     style: GoogleFonts.poppins(
//                                       color: ChefColors.danger,
//                                       fontSize: 10.5,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                   style: TextButton.styleFrom(
//                                     padding: EdgeInsets.zero,
//                                     visualDensity: VisualDensity.compact,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(height: 6),
//                           Row(
//                             children: dialogMonthsList.map((mName) {
//                               final prefix = mName.split(' ')[0].toLowerCase();
//                               final isPaid = userPaidSet.keys.any(
//                                 (k) => k.contains(prefix),
//                               );
//                               final isSelected =
//                                   (selectedMonthInDialog == mName);

//                               return Expanded(
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 3,
//                                   ),
//                                   child: _buildCompactMonthCard(
//                                     monthName: mName,
//                                     isSelected: isSelected,
//                                     isPaid: isPaid,
//                                     onTap: () {
//                                       setDialogState(() {
//                                         selectedMonthInDialog = mName;
//                                         utrController.text =
//                                             userPaidSet[prefix] ?? '';
//                                         duplicateWarning = '';
//                                       });
//                                     },
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                           const SizedBox(height: 14),
//                           _sectionTitle(
//                             'Payment details',
//                             Icons.payments_outlined,
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Expanded(
//                                 flex: 4,
//                                 child: SizedBox(
//                                   height: 46,
//                                   child: TextField(
//                                     controller: amountController,
//                                     keyboardType: TextInputType.number,
//                                     style: GoogleFonts.poppins(fontSize: 12.5),
//                                     decoration: const InputDecoration(
//                                       isDense: true,
//                                       labelText: 'Amount (₹)',
//                                       prefixIcon: Icon(
//                                         Icons.currency_rupee_rounded,
//                                         size: 16,
//                                       ),
//                                       contentPadding: EdgeInsets.symmetric(
//                                         horizontal: 10,
//                                         vertical: 11,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 flex: 6,
//                                 child: SizedBox(
//                                   height: 46,
//                                   child: TextField(
//                                     controller: utrController,
//                                     style: GoogleFonts.poppins(fontSize: 12.5),
//                                     onChanged: (val) {
//                                       final trimmed = val.trim();

//                                       if (_isRealUtrNumber(trimmed)) {
//                                         String foundInMonth = '';
//                                         bool foundDuplicate = false;

//                                         _userPaymentMap.forEach((uId, mData) {
//                                           if (uId != student.id) {
//                                             mData.forEach((m, txn) {
//                                               if (_isRealUtrNumber(txn) &&
//                                                   txn.trim().toLowerCase() ==
//                                                       trimmed.toLowerCase()) {
//                                                 foundDuplicate = true;
//                                                 foundInMonth = m;
//                                               }
//                                             });
//                                           }
//                                         });

//                                         setDialogState(() {
//                                           if (foundDuplicate) {
//                                             duplicateWarning =
//                                                 'Warning: This UTR was already recorded for another student in $foundInMonth.';
//                                           } else {
//                                             duplicateWarning = '';
//                                           }
//                                         });
//                                       } else {
//                                         setDialogState(
//                                           () => duplicateWarning = '',
//                                         );
//                                       }
//                                     },
//                                     decoration: InputDecoration(
//                                       isDense: true,
//                                       labelText: 'UTR / Txn ID *',
//                                       prefixIcon: const Icon(
//                                         Icons.confirmation_number_outlined,
//                                         size: 16,
//                                       ),
//                                       contentPadding:
//                                           const EdgeInsets.symmetric(
//                                             horizontal: 10,
//                                             vertical: 11,
//                                           ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           if (duplicateWarning.isNotEmpty) ...[
//                             const SizedBox(height: 6),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 6,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: ChefColors.dangerSoft,
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: ChefColors.danger.withValues(
//                                     alpha: 0.3,
//                                   ),
//                                 ),
//                               ),
//                               child: Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.warning_amber_rounded,
//                                     color: ChefColors.danger,
//                                     size: 15,
//                                   ),
//                                   const SizedBox(width: 6),
//                                   Expanded(
//                                     child: Text(
//                                       duplicateWarning,
//                                       style: GoogleFonts.poppins(
//                                         color: ChefColors.danger,
//                                         fontSize: 10,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: SizedBox(
//                                   height: 46,
//                                   child: TextField(
//                                     controller: fatherPhoneController,
//                                     keyboardType: TextInputType.phone,
//                                     style: GoogleFonts.poppins(fontSize: 12.5),
//                                     decoration: const InputDecoration(
//                                       isDense: true,
//                                       labelText: "Father's Phone",
//                                       prefixIcon: Icon(
//                                         Icons.family_restroom_outlined,
//                                         size: 16,
//                                       ),
//                                       contentPadding: EdgeInsets.symmetric(
//                                         horizontal: 10,
//                                         vertical: 11,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: SizedBox(
//                                   height: 46,
//                                   child: TextField(
//                                     controller: dateController,
//                                     style: GoogleFonts.poppins(fontSize: 12.5),
//                                     decoration: const InputDecoration(
//                                       isDense: true,
//                                       labelText: 'Date (YYYY-MM-DD)',
//                                       prefixIcon: Icon(
//                                         Icons.calendar_today_outlined,
//                                         size: 16,
//                                       ),
//                                       contentPadding: EdgeInsets.symmetric(
//                                         horizontal: 10,
//                                         vertical: 11,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       border: Border(top: BorderSide(color: ChefColors.border)),
//                       borderRadius: BorderRadius.vertical(
//                         bottom: Radius.circular(20),
//                       ),
//                     ),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 44,
//                       child: ElevatedButton.icon(
//                         onPressed: () async {
//                           if (utrController.text.trim().isEmpty) {
//                             Get.snackbar(
//                               'UTR missing',
//                               'Please enter a UTR or receipt ID for $selectedMonthInDialog.',
//                               backgroundColor: ChefColors.danger,
//                               colorText: Colors.white,
//                               snackPosition: SnackPosition.BOTTOM,
//                               margin: const EdgeInsets.all(12),
//                             );
//                             return;
//                           }

//                           final parsedAmount =
//                               num.tryParse(amountController.text.trim()) ??
//                               4000;

//                           try {
//                             final res = await http.post(
//                               Uri.parse(ApiEndpoints.adminManualPayment),
//                               headers: {'Content-Type': 'application/json'},
//                               body: jsonEncode({
//                                 'userId': student.id,
//                                 'amount': parsedAmount,
//                                 'paymentsData': [
//                                   {
//                                     'month': selectedMonthInDialog,
//                                     'transactionId': utrController.text.trim(),
//                                   },
//                                 ],
//                                 'fatherPhone': fatherPhoneController.text
//                                     .trim(),
//                                 'paymentDate': dateController.text.trim(),
//                               }),
//                             );

//                             final resData = json.decode(res.body);

//                             if (res.statusCode == 200) {
//                               Navigator.of(dialogContext).pop();
//                               await _loadAllData();

//                               Get.snackbar(
//                                 'Payment updated',
//                                 'Payment for $selectedMonthInDialog saved and access granted.',
//                                 backgroundColor: ChefColors.success,
//                                 colorText: Colors.white,
//                                 snackPosition: SnackPosition.BOTTOM,
//                                 margin: const EdgeInsets.all(12),
//                               );
//                             } else {
//                               Get.snackbar(
//                                 'Payment Rejected',
//                                 resData['message'] ??
//                                     'The payment could not be recorded.',
//                                 backgroundColor: ChefColors.danger,
//                                 colorText: Colors.white,
//                                 duration: const Duration(seconds: 4),
//                                 snackPosition: SnackPosition.BOTTOM,
//                                 margin: const EdgeInsets.all(12),
//                               );
//                             }
//                           } catch (e) {
//                             Get.snackbar(
//                               'Connection error',
//                               'Please check the server connection and try again.',
//                               backgroundColor: ChefColors.danger,
//                               colorText: Colors.white,
//                               snackPosition: SnackPosition.BOTTOM,
//                               margin: const EdgeInsets.all(12),
//                             );
//                           }
//                         },
//                         icon: const Icon(Icons.check_rounded, size: 18),
//                         label: Text(
//                           'Save $selectedMonthInDialog payment & approve',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: ChefColors.primary,
//                           foregroundColor: const Color(0xFF241C00),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(11),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//       barrierDismissible: true,
//     );
//   }

//   Widget _buildCompactMonthCard({
//     required String monthName,
//     required bool isSelected,
//     required bool isPaid,
//     required VoidCallback onTap,
//   }) {
//     Color bgColor;
//     Color borderColor;

//     if (isSelected) {
//       bgColor = const Color(0xFFFFF9E6);
//       borderColor = const Color(0xFFF59E0B);
//     } else if (isPaid) {
//       bgColor = const Color(0xFFF0FDF4);
//       borderColor = const Color(0xFFBBF7D0);
//     } else {
//       bgColor = const Color(0xFFFEF2F2);
//       borderColor = const Color(0xFFFECACA);
//     }

//     final shortName = monthName.replaceAll(' 2026', '');

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(10),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: borderColor,
//             width: isSelected || isPaid ? 1.4 : 1.0,
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 14,
//                   height: 14,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(3),
//                     color: isSelected
//                         ? const Color(0xFFF59E0B)
//                         : Colors.transparent,
//                     border: Border.all(
//                       color: isSelected
//                           ? const Color(0xFFF59E0B)
//                           : (isPaid
//                                 ? const Color(0xFF22C55E)
//                                 : const Color(0xFFEF4444)),
//                       width: 1.5,
//                     ),
//                   ),
//                   child: isSelected
//                       ? const Icon(Icons.check, size: 10, color: Colors.white)
//                       : null,
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 5,
//                     vertical: 1.5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? const Color(0xFFFDE68A)
//                         : (isPaid
//                               ? const Color(0xFFDCFCE7)
//                               : const Color(0xFFFEE2E2)),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     isSelected ? 'SEL' : (isPaid ? 'PAID' : 'PEND'),
//                     style: GoogleFonts.poppins(
//                       color: isSelected
//                           ? const Color(0xFF92400E)
//                           : (isPaid
//                                 ? const Color(0xFF16A34A)
//                                 : const Color(0xFFDC2626)),
//                       fontSize: 8,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               shortName,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: GoogleFonts.poppins(
//                 color: ChefColors.text,
//                 fontSize: 11.5,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             Text(
//               '2026',
//               style: GoogleFonts.poppins(
//                 color: ChefColors.muted,
//                 fontSize: 9.5,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String title, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, size: 15, color: ChefColors.primaryDark),
//         const SizedBox(width: 6),
//         Text(
//           title,
//           style: GoogleFonts.poppins(
//             color: ChefColors.text,
//             fontSize: 11.5,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _exportExcel() async {
//     final group = _tabController.index == 0 ? 'Junior' : 'Senior';

//     String backendGender = 'All';
//     if (selectedFilterCategory.contains('Boy')) {
//       backendGender = 'Male';
//     } else if (selectedFilterCategory.contains('Girl')) {
//       backendGender = 'Female';
//     }

//     final urlString =
//         '${ApiEndpoints.adminExportExcel}?yearGroup=$group&gender=${Uri.encodeComponent(backendGender)}&month=${Uri.encodeComponent(selectedMonth)}&unpaidOnly=$showUnpaidOnly';

//     Get.snackbar(
//       'Exporting Excel',
//       showUnpaidOnly
//           ? 'Generating unpaid students report...'
//           : 'Generating mess report...',
//       snackPosition: SnackPosition.BOTTOM,
//       margin: const EdgeInsets.all(12),
//       duration: const Duration(seconds: 2),
//     );

//     try {
//       final response = await http.get(
//         Uri.parse(urlString),
//         headers: {'Authorization': 'Bearer ${ApiEndpoints.adminAuthToken}'},
//       );

//       if (response.statusCode == 200) {
//         final blob = html.Blob([
//           response.bodyBytes,
//         ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
//         final blobUrl = html.Url.createObjectUrlFromBlob(blob);

//         final cleanMonth = selectedMonth.replaceAll(' ', '_');
//         final prefix = showUnpaidOnly ? 'UNPAID_' : '';
//         final cleanCategory = selectedFilterCategory.replaceAll(' ', '_');
//         final filename =
//             'Chef_${prefix}Mess_Report_${group}_${cleanCategory}_$cleanMonth.xlsx';

//         final anchor = html.AnchorElement(href: blobUrl)
//           ..setAttribute('download', filename)
//           ..style.display = 'none';

//         html.document.body?.children.add(anchor);
//         anchor.click();

//         anchor.remove();
//         html.Url.revokeObjectUrl(blobUrl);

//         Get.snackbar(
//           'Download Complete',
//           '$filename saved successfully.',
//           backgroundColor: ChefColors.success,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//           margin: const EdgeInsets.all(12),
//         );
//       } else {
//         Get.snackbar(
//           'Download Failed',
//           'Server returned code ${response.statusCode}',
//           backgroundColor: ChefColors.danger,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//           margin: const EdgeInsets.all(12),
//         );
//       }
//     } catch (e) {
//       debugPrint('Excel export error: $e');
//       Get.snackbar(
//         'Download Failed',
//         'Could not complete file download: $e',
//         backgroundColor: ChefColors.danger,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: const EdgeInsets.all(12),
//       );
//     }
//   }

//   Widget _buildExcelExportButton() {
//     return OutlinedButton.icon(
//       onPressed: _exportExcel,
//       icon: Icon(
//         showUnpaidOnly
//             ? Icons.warning_amber_rounded
//             : Icons.file_download_outlined,
//         size: 17,
//       ),
//       label: Text(
//         showUnpaidOnly ? 'Unpaid Excel' : 'Export Excel',
//         style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w800),
//       ),
//       style: OutlinedButton.styleFrom(
//         foregroundColor: const Color(0xFF1A1A1A),
//         side: const BorderSide(color: Color(0xFF1A1A1A)),
//         backgroundColor: showUnpaidOnly
//             ? ChefColors.dangerSoft
//             : const Color(0xFFF9FAFC),
//         padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
//       ),
//     );
//   }
// }