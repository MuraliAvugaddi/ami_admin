import 'dart:async';

import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// STUDENTS — full student directory
// name, enrollment, course, block / room, phone, father, email,
// mess access. Block filter + search. Phone + website layout.
// ============================================================

class StudentsDirectoryScreen extends StatefulWidget {
  const StudentsDirectoryScreen({super.key});

  @override
  State<StudentsDirectoryScreen> createState() => _StudentsDirectoryScreenState();
}

class _StudentsDirectoryScreenState extends State<StudentsDirectoryScreen> {
  final HostelStaffService _service = HostelStaffService();
  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> _list = [];
  List<String> _blocks = [];
  String _block = '';
  int _total = 0;
  bool _loading = true;
  Timer? _debounce;

  static const List<Color> _avatarColors = [
    Color(0xFFFFC800),
    Color(0xFF00897B),
    Color(0xFF3949AB),
    Color(0xFFE58F00),
    Color(0xFF7656A6),
    Color(0xFF2E7D32),
    Color(0xFFD84315),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _service.students(_search.text.trim(), block: _block);
    if (!mounted) return;
    setState(() {
      _list = asMapList(res['students']);
      _blocks = (res['blocks'] is List) ? (res['blocks'] as List).map((e) => '$e').toList() : _blocks;
      _total = (res['total'] is num) ? (res['total'] as num).toInt() : _list.length;
      _loading = false;
    });
    if (res['success'] != true) showResult(res);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _v(Map<String, dynamic> s, String key) {
    final value = '${s[key] ?? ''}'.trim();
    return value == 'null' ? '' : value;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _color(String name) => _avatarColors[name.isEmpty ? 0 : name.codeUnitAt(0) % _avatarColors.length];

  bool _hasAccess(Map<String, dynamic> s) {
    final till = DateTime.tryParse(_v(s, 'accessExpiresAt'));
    return s['isApproved'] == true && till != null && till.isAfter(DateTime.now());
  }

  String _courseYear(Map<String, dynamic> s) {
    final course = _v(s, 'course');
    final year = _v(s, 'year');
    if (course.isEmpty && year.isEmpty) return '';
    if (year.isEmpty) return course;
    return course.isEmpty ? 'Year $year' : '$course • Year $year';
  }

  Future<void> _whatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final number = digits.length == 10 ? '91$digits' : digits;
    await launchUrl(Uri.parse('https://wa.me/$number'), mode: LaunchMode.externalApplication);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copied', text,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: HostelColors.textPrimary,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2));
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: hostelAppBar('Students', subtitle: '$_total students in hostel'),
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
                        SizedBox(height: 140),
                        Center(child: CircularProgressIndicator(color: HostelColors.chefYellow)),
                      ])
                    : _list.isEmpty
                        ? ListView(children: const [
                            HostelEmpty(
                              icon: Icons.person_search_rounded,
                              title: 'No students found',
                              subtitle: 'Try another name, room or block.',
                            ),
                          ])
                        : HostelResponsiveList(
                            itemCount: _list.length,
                            maxColumns: 2,
                            itemBuilder: (_, i) => _studentCard(_list[i]),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
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
          HostelSearchField(
            controller: _search,
            hint: 'Search name, room, phone, enrollment, course…',
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 450), _load);
            },
          ),
          if (_blocks.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  HostelFilterPill(
                    label: 'All blocks',
                    selected: _block.isEmpty,
                    icon: Icons.apartment_rounded,
                    onTap: () {
                      setState(() => _block = '');
                      _load();
                    },
                  ),
                  for (final b in _blocks) ...[
                    const SizedBox(width: 8),
                    HostelFilterPill(
                      label: 'Block ${b.toUpperCase()}',
                      selected: _block.toLowerCase() == b.toLowerCase(),
                      onTap: () {
                        setState(() => _block = b);
                        _load();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _loading ? 'Loading…' : 'Showing ${_list.length} student${_list.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STUDENT CARD
  // ------------------------------------------------------------

  Widget _studentCard(Map<String, dynamic> s) {
    final name = _v(s, 'name').isEmpty ? 'Student' : _v(s, 'name');
    final block = _v(s, 'hostelblock');
    final room = _v(s, 'room');
    final phone = _v(s, 'phonenumber');
    final father = _v(s, 'fatherPhone');
    final enroll = _v(s, 'enrollmentNo');
    final courseYear = _courseYear(s);
    final access = _hasAccess(s);
    final color = _color(name);

    return HostelCard(
      padding: EdgeInsets.zero,
      onTap: () => _openDetails(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- top: avatar + name + room badge ----
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _initials(name),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color == HostelColors.chefYellow ? const Color(0xFF8A6A00) : color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HostelColors.textPrimary,
                        ),
                      ),
                      Text(
                        [if (courseYear.isNotEmpty) courseYear, if (enroll.isNotEmpty) enroll].join('  •  ').isEmpty
                            ? 'Profile not completed'
                            : [if (courseYear.isNotEmpty) courseYear, if (enroll.isNotEmpty) enroll].join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      HostelChip(
                        access ? 'Mess active' : 'Mess not active',
                        color: access ? HostelColors.green : HostelColors.greyBlue,
                        icon: access ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _roomBadge(block, room),
              ],
            ),
          ),

          const Divider(height: 1, color: HostelColors.borderColor),

          // ---- contact rows ----
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Column(
              children: [
                _contactRow(Icons.phone_android_rounded, 'Student', phone, HostelColors.green),
                const SizedBox(height: 6),
                _contactRow(Icons.family_restroom_rounded, 'Father', father, HostelColors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomBadge(String block, String room) {
    final hasRoom = block.isNotEmpty || room.isNotEmpty;
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: hasRoom ? HostelColors.chefYellow.withValues(alpha: 0.16) : HostelColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasRoom ? HostelColors.chefYellow.withValues(alpha: 0.6) : HostelColors.borderColor),
      ),
      child: Column(
        children: [
          Text(
            room.isEmpty ? '—' : room,
            style: GoogleFonts.poppins(
              fontSize: 17,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: hasRoom ? HostelColors.textPrimary : HostelColors.textSecondary,
            ),
          ),
          Text(
            block.isEmpty ? 'No room' : 'Block ${block.toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: HostelColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String phone, Color color) {
    final has = phone.isNotEmpty;
    return Row(
      children: [
        Icon(icon, size: 17, color: has ? color : HostelColors.borderColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            has ? phone : 'Not added',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: has ? FontWeight.w600 : FontWeight.w400,
              color: has ? HostelColors.textPrimary : HostelColors.textSecondary,
              fontStyle: has ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
        if (has) ...[
          _miniAction(Icons.call_rounded, color, () => callNumber(phone), 'Call'),
          _miniAction(Icons.chat_rounded, const Color(0xFF25A244), () => _whatsApp(phone), 'WhatsApp'),
        ],
      ],
    );
  }

  Widget _miniAction(IconData icon, Color color, VoidCallback onTap, String tip) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAILS SHEET (tap a card)
  // ------------------------------------------------------------

  void _openDetails(Map<String, dynamic> s) {
    final name = _v(s, 'name').isEmpty ? 'Student' : _v(s, 'name');
    final till = DateTime.tryParse(_v(s, 'accessExpiresAt'));
    final joined = DateTime.tryParse(_v(s, 'createdAt'));
    final access = _hasAccess(s);
    final color = _color(name);

    final rows = <(IconData, String, String)>[
      (Icons.badge_outlined, 'Enrollment No.', _v(s, 'enrollmentNo')),
      (Icons.school_outlined, 'Course / Year', _courseYear(s)),
      (Icons.apartment_rounded, 'Block', _v(s, 'hostelblock').toUpperCase()),
      (Icons.meeting_room_outlined, 'Room', _v(s, 'room')),
      (Icons.wc_rounded, 'Gender', _v(s, 'gender')),
      (Icons.phone_android_rounded, 'Student phone', _v(s, 'phonenumber')),
      (Icons.family_restroom_rounded, 'Father phone', _v(s, 'fatherPhone')),
      (Icons.mail_outline_rounded, 'Email', _v(s, 'email')),
      (Icons.restaurant_rounded, 'Mess access till', till == null ? '' : DateFormat('d MMM yyyy').format(till.toLocal())),
      (Icons.event_outlined, 'Joined app', joined == null ? '' : DateFormat('d MMM yyyy').format(joined.toLocal())),
    ];

    Get.bottomSheet(
      Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 620, maxHeight: Get.height * 0.88),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(color: HostelColors.borderColor, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _initials(name),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color == HostelColors.chefYellow ? const Color(0xFF8A6A00) : color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w800, color: HostelColors.textPrimary)),
                  const SizedBox(height: 6),
                  HostelChip(
                    access ? 'Mess active' : 'Mess not active',
                    color: access ? HostelColors.green : HostelColors.greyBlue,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _bigCall('Call student', _v(s, 'phonenumber'), HostelColors.green)),
                      const SizedBox(width: 10),
                      Expanded(child: _bigCall('Call father', _v(s, 'fatherPhone'), HostelColors.blue)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: HostelColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < rows.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 50, color: HostelColors.borderColor),
                          ListTile(
                            dense: true,
                            leading: Icon(rows[i].$1, size: 20, color: HostelColors.textSecondary),
                            title: Text(rows[i].$2, style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary)),
                            subtitle: Text(
                              rows[i].$3.isEmpty ? '—' : rows[i].$3,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: HostelColors.textPrimary,
                              ),
                            ),
                            trailing: rows[i].$3.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Copy',
                                    icon: const Icon(Icons.copy_rounded, size: 17),
                                    onPressed: () => _copy(rows[i].$3),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _bigCall(String label, String phone, Color color) {
    final has = phone.isNotEmpty;
    return ElevatedButton.icon(
      onPressed: has ? () => callNumber(phone) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: HostelColors.background,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.call_rounded, size: 18),
      label: Text(has ? label : 'No number', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}
