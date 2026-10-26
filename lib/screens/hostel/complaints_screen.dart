import 'dart:async';

import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/complaint_detail_screen.dart';
import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ============================================================
// COMPLAINTS — room repair list for director / warden / attender
// Tabs: Active • Escalated • New • Done
// ============================================================

class ComplaintsScreen extends StatefulWidget {
  final String startTab;

  const ComplaintsScreen({super.key, this.startTab = 'active'});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  static const List<String> _tabs = ['active', 'escalated', 'new', 'done'];
  static const List<String> _tabNames = ['Active', 'Escalated', 'New', 'Done'];

  final HostelStaffService _service = HostelStaffService();
  final TextEditingController _search = TextEditingController();

  late final TabController _tab;
  String _category = '';
  DateTimeRange? _range;
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  Timer? _debounce;
  Worker? _live;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this, initialIndex: _tabs.indexOf(widget.startTab).clamp(0, 3));
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _load();
    });
    if (Get.isRegistered<HostelStaffController>()) {
      _live = ever(Get.find<HostelStaffController>().changes, (_) => _load(silent: true));
    }
    _load();
  }

  @override
  void dispose() {
    _live?.dispose();
    _debounce?.cancel();
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final day = DateFormat('yyyy-MM-dd');
    final res = await _service.complaints(
      tab: _tabs[_tab.index],
      search: _search.text.trim(),
      category: _category,
      from: _range == null ? '' : day.format(_range!.start),
      to: _range == null ? '' : day.format(_range!.end),
    );
    if (!mounted) return;
    setState(() {
      _list = asMapList(res['complaints']);
      _loading = false;
    });
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: now,
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
      helpText: 'Complaints raised between',
      saveText: 'Show',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: HostelColors.chefYellow,
            onPrimary: Colors.black,
            secondary: HostelColors.chefYellow,
            onSurface: HostelColors.textPrimary,
          ),
        ),
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720), child: child!),
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _range = picked);
    _load();
  }

  void _quickRange(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() => _range = DateTimeRange(start: today.subtract(Duration(days: days - 1)), end: today));
    _load();
  }

  String get _rangeText {
    if (_range == null) return 'All dates';
    final f = DateFormat('d MMM');
    final same = DateUtils.isSameDay(_range!.start, _range!.end);
    return same ? DateFormat('d MMM yyyy').format(_range!.start) : '${f.format(_range!.start)} – ${f.format(_range!.end)}';
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: AppBar(
        backgroundColor: HostelColors.chefYellow,
        surfaceTintColor: HostelColors.chefYellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Room Complaints',
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickRange,
            icon: Badge(
              isLabelVisible: _range != null,
              smallSize: 8,
              child: const Icon(Icons.calendar_month_rounded, color: Colors.black),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: false,
          labelColor: Colors.black,
          unselectedLabelColor: const Color(0xFF6B5A10),
          indicatorColor: Colors.black,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500),
          tabs: _tabNames.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: HostelPage(
        child: Column(
        children: [
          _filters(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.black,
              onRefresh: _load,
              child: _loading
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator(color: HostelColors.chefYellow)),
                    ])
                  : _list.isEmpty
                      ? ListView(children: const [
                          HostelEmpty(
                            icon: Icons.task_alt_rounded,
                            title: 'Nothing here',
                            subtitle: 'No complaints in this list right now.',
                          ),
                        ])
                      : HostelResponsiveList(
                          itemCount: _list.length,
                          maxColumns: 2,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
                          itemBuilder: (_, i) => ComplaintCard(
                            complaint: _list[i],
                            onTap: () async {
                              await Get.to(() => ComplaintDetailScreen(complaintId: '${_list[i]['_id']}'));
                              _load(silent: true);
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _filters() {
    const cats = ['', 'electrical', 'plumbing', 'carpentry', 'cleaning', 'other'];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HostelColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HostelSearchField(controller: _search, hint: 'Search student, room, block, code…', onChanged: _onSearch),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < cats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  HostelFilterPill(
                    label: cats[i].isEmpty ? 'All' : HostelLabels.category(cats[i]),
                    icon: cats[i].isEmpty ? null : HostelLabels.categoryIcon(cats[i]),
                    selected: _category == cats[i],
                    onTap: () {
                      setState(() => _category = cats[i]);
                      _load();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ---- date row (pills go below on small phones) ----
          LayoutBuilder(
            builder: (context, box) {
              final pills = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _quick('Today', 1),
                  const SizedBox(width: 6),
                  _quick('7 days', 7),
                  const SizedBox(width: 6),
                  _quick('30 days', 30),
                ],
              );
              if (box.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_dateBox(), const SizedBox(height: 8), pills],
                );
              }
              return Row(children: [Expanded(child: _dateBox()), const SizedBox(width: 8), pills]);
            },
          ),
          const SizedBox(height: 8),
          Text(
            _loading ? 'Loading…' : '${_list.length} complaint${_list.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _dateBox() {
    return InkWell(
      onTap: _pickRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _range == null ? HostelColors.background : HostelColors.chefYellow.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _range == null ? HostelColors.borderColor : HostelColors.chefYellow),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, size: 17, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_rangeText, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            if (_range != null)
              InkWell(
                onTap: () {
                  setState(() => _range = null);
                  _load();
                },
                child: const Icon(Icons.close_rounded, size: 17),
              )
            else
              const Icon(Icons.expand_more_rounded, size: 18, color: HostelColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _quick(String label, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = _range != null &&
        DateUtils.isSameDay(_range!.end, today) &&
        _range!.end.difference(_range!.start).inDays == days - 1;
    return HostelFilterPill(label: label, selected: selected, onTap: () => _quickRange(days));
  }
}

// ============================================================
// ONE COMPLAINT ROW (used by the worker screen too)
// ============================================================

class ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onTap;
  final Widget? trailing;

  const ComplaintCard({super.key, required this.complaint, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final category = '${c['category']}';
    final status = '${c['status']}';
    final level = '${c['level'] ?? 'team'}';
    final worker = asMapOf(c['assignedTo']);
    final hours = hoursOpen(c['createdAt']);
    final open = ['open', 'in_progress', 'reopened'].contains(status);
    final color = HostelLabels.categoryColor(category);

    return HostelCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(HostelLabels.categoryIcon(category), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c['title'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: HostelColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c['studentName'] ?? ''} • Block ${c['hostelblock'] ?? '-'} • Room ${c['room'] ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              HostelChip(HostelLabels.status(status), color: HostelLabels.statusColor(status)),
              if (level == 'warden') const HostelChip('At warden', color: HostelColors.purple, icon: Icons.arrow_upward_rounded),
              if (level == 'director') const HostelChip('At director', color: HostelColors.red, icon: Icons.priority_high_rounded),
              if (worker.isNotEmpty) HostelChip('${worker['name']}', color: HostelColors.greyBlue, icon: Icons.engineering_rounded),
              HostelChip(
                open ? '$hours h open' : agoText(c['createdAt']),
                color: open && hours >= 24 ? HostelColors.red : HostelColors.textSecondary,
                icon: Icons.schedule_rounded,
              ),
              Text(
                '${c['code'] ?? ''}',
                style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
