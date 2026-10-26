import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/complaint_detail_screen.dart';
import 'package:ami_admin/screens/hostel/complaints_screen.dart';
import 'package:ami_admin/screens/hostel/hostel_session.dart';
import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/screens/hostel/staff_notifications_screen.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// REPAIR TEAM — electrician / plumber / carpenter / cleaner
// New jobs for my trade • My jobs • Done
// ============================================================

class WorkerJobsScreen extends StatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  State<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends State<WorkerJobsScreen> with SingleTickerProviderStateMixin {
  static const List<String> _tabs = ['new', 'mine', 'done'];

  final HostelStaffService _service = HostelStaffService();
  final HostelStaffController _live = Get.isRegistered<HostelStaffController>()
      ? Get.find<HostelStaffController>()
      : Get.put(HostelStaffController(), permanent: true);

  late final TabController _tab;
  final Map<String, List<Map<String, dynamic>>> _lists = {'new': [], 'mine': [], 'done': []};
  bool _loading = true;
  String _accepting = '';
  Worker? _changes;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
    _changes = ever(_live.changes, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _changes?.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final results = await Future.wait(_tabs.map((t) => _service.complaints(tab: t)));
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _tabs.length; i++) {
        _lists[_tabs[i]] = asMapList(results[i]['complaints']);
      }
      // done list: only my work
      _lists['done'] = _lists['done']!.where((c) => '${asMapOf(c['assignedTo'])['_id']}' == StaffSession.id).toList();
      _loading = false;
    });
  }

  Future<void> _accept(Map<String, dynamic> c) async {
    setState(() => _accepting = '${c['_id']}');
    final res = await _service.complaintAction('${c['_id']}', 'accept');
    if (!mounted) return;
    setState(() => _accepting = '');
    showResult(res);
    if (res['success'] == true) {
      await _load(silent: true);
      _tab.animateTo(1);
    }
  }

  Future<void> _open(Map<String, dynamic> c) async {
    await Get.to(() => ComplaintDetailScreen(complaintId: '${c['_id']}'));
    _load(silent: true);
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final trade = StaffSession.tradeName(StaffSession.trade);
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: AppBar(
        backgroundColor: HostelColors.chefYellow,
        surfaceTintColor: HostelColors.chefYellow,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Jobs',
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${StaffSession.name} • $trade',
              style: GoogleFonts.poppins(color: const Color(0xFF5C4900), fontSize: 10.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Obx(
            () => IconButton(
              onPressed: () async {
                await Get.to(() => const StaffNotificationsScreen());
                _live.loadUnread();
              },
              icon: Badge(
                isLabelVisible: _live.unread.value > 0,
                label: Text('${_live.unread.value}'),
                child: const Icon(Icons.notifications_rounded, color: Colors.black),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: HostelSession.confirmLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.black,
          unselectedLabelColor: const Color(0xFF6B5A10),
          indicatorColor: Colors.black,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'New (${_lists['new']!.length})'),
            Tab(text: 'Working (${_lists['mine']!.length})'),
            const Tab(text: 'Done'),
          ],
        ),
      ),
      body: HostelPage(
        maxWidth: 1000,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: HostelColors.chefYellow))
          : TabBarView(
              controller: _tab,
              children: [
                _list('new', 'No new jobs', 'New $trade complaints will come here.'),
                _list('mine', 'No jobs in hand', 'Accept a job from the New tab.'),
                _list('done', 'Nothing done yet', 'Repaired jobs will show here.'),
              ],
            ),
      ),
    );
  }

  Widget _list(String key, String emptyTitle, String emptySub) {
    final list = _lists[key]!;
    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _load,
      child: list.isEmpty
          ? ListView(children: [HostelEmpty(icon: Icons.handyman_rounded, title: emptyTitle, subtitle: emptySub)])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = list[i];
                return ComplaintCard(
                  complaint: c,
                  onTap: () => _open(c),
                  trailing: key == 'new' ? _acceptButton(c) : null,
                );
              },
            ),
    );
  }

  Widget _acceptButton(Map<String, dynamic> c) {
    final busy = _accepting == '${c['_id']}';
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: _accepting.isNotEmpty ? null : () => _accept(c),
        style: ElevatedButton.styleFrom(
          backgroundColor: HostelColors.chefYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Text('Accept', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
