import 'dart:convert';

import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// ============================================================
// COMPLAINT DETAIL — what each person can do:
//  worker   : accept job, mark repaired (with photo)
//  attender : assign to a worker, add note, mark repaired
//  warden   : + write report (after 48 h)
//  director : + final close (after 64 h)
// ============================================================

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final HostelStaffService _service = HostelStaffService();

  Map<String, dynamic> _c = {};
  bool _loading = true;
  bool _busy = false;

  String get _role => StaffSession.role;
  String get _status => '${_c['status'] ?? ''}';
  String get _level => '${_c['level'] ?? 'team'}';
  bool get _isOpen => ['open', 'in_progress', 'reopened'].contains(_status);
  Map<String, dynamic> get _worker => asMapOf(_c['assignedTo']);
  bool get _isMine => '${_worker['_id'] ?? ''}' == StaffSession.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _service.complaint(widget.complaintId);
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) _c = asMapOf(res['complaint']);
      _loading = false;
    });
    if (res['success'] != true) showResult(res);
  }

  Future<void> _run(String action, [Map<String, dynamic>? body]) async {
    setState(() => _busy = true);
    final res = await _service.complaintAction(widget.complaintId, action, body);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true && res['complaint'] != null) _c = asMapOf(res['complaint']);
    });
    showResult(res);
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _accept() => _run('accept');

  Future<void> _note() async {
    final note = await askText('Add a note', hint: 'e.g. Part ordered, will fix tomorrow');
    if (note == null || note.isEmpty) return;
    await _run('note', {'note': note});
  }

  Future<void> _assign() async {
    setState(() => _busy = true);
    final res = await _service.team(role: 'worker');
    if (!mounted) return;
    setState(() => _busy = false);

    final workers = asMapList(res['staff']).where((w) => w['isActive'] != false).toList();
    if (workers.isEmpty) {
      showResult({'success': false, 'message': 'No repair team added yet. Ask the director to add workers.'});
      return;
    }

    // same trade first
    const tradeFor = {
      'electrical': 'electrician',
      'plumbing': 'plumber',
      'carpentry': 'carpenter',
      'cleaning': 'cleaner',
    };
    final want = tradeFor['${_c['category']}'] ?? '';
    workers.sort((a, b) => (a['trade'] == want ? 0 : 1).compareTo(b['trade'] == want ? 0 : 1));

    final picked = await Get.bottomSheet<Map<String, dynamic>>(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: HostelColors.borderColor, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Assign to', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: workers.length,
                itemBuilder: (_, i) {
                  final w = workers[i];
                  final match = w['trade'] == want;
                  return ListTile(
                    onTap: () => Get.back(result: w),
                    leading: CircleAvatar(
                      backgroundColor: match ? HostelColors.chefYellow : HostelColors.background,
                      child: const Icon(Icons.engineering_rounded, color: Colors.black87, size: 20),
                    ),
                    title: Text('${w['name']}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${StaffSession.tradeName('${w['trade']}')} • ${w['phone']}',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary),
                    ),
                    trailing: match ? const HostelChip('Best match', color: HostelColors.green) : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
    if (picked == null) return;
    await _run('assign', {'workerId': picked['_id']});
  }

  Future<void> _repaired() async {
    final noteCtrl = TextEditingController();
    String? photo;
    final picker = ImagePicker();

    final ok = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Mark as repaired', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'What did you repair? (e.g. Changed fan capacitor)',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: HostelColors.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 55, maxWidth: 1280);
                    if (file == null) return;
                    final bytes = await file.readAsBytes();
                    setLocal(() => photo = base64Encode(bytes));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: photo == null ? HostelColors.borderColor : HostelColors.green),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(photo == null ? Icons.camera_alt_rounded : Icons.check_circle_rounded,
                      color: photo == null ? Colors.black54 : HostelColors.green, size: 18),
                  label: Text(
                    photo == null ? 'Add photo (optional)' : 'Photo added',
                    style: GoogleFonts.poppins(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HostelColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () => Get.back(result: true),
              child: const Text('Repaired'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (noteCtrl.text.trim().isEmpty) {
      showResult({'success': false, 'message': 'Write what you repaired.'});
      return;
    }
    await _run('repaired', {'note': noteCtrl.text.trim(), if (photo != null) 'photoBase64': photo});
  }

  Future<void> _wardenReport() async {
    final cause = TextEditingController();
    final action = TextEditingController();
    final solution = TextEditingController();
    bool markRepaired = false;

    Widget field(TextEditingController c, String label, String hint) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: c,
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: GoogleFonts.poppins(fontSize: 12.5),
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: HostelColors.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

    final ok = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Warden report', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(cause, 'Why was it late?', 'e.g. Electrician on leave, part not available'),
                field(action, 'Action taken', 'e.g. Called outside electrician'),
                field(solution, 'Solution / next step', 'e.g. Will be fixed by tomorrow 11 AM'),
                CheckboxListTile(
                  value: markRepaired,
                  onChanged: (v) => setLocal(() => markRepaired = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: HostelColors.green,
                  title: Text('It is repaired now', style: GoogleFonts.poppins(fontSize: 13)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HostelColors.chefYellow,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              onPressed: () => Get.back(result: true),
              child: const Text('Send report'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _run('warden-report', {
      'cause': cause.text.trim(),
      'actionTaken': action.text.trim(),
      'solution': solution.text.trim(),
      'markRepaired': markRepaired,
    });
  }

  Future<void> _directorClose() async {
    final note = await askText('Close complaint', hint: 'Your final decision / note', ok: 'Close');
    if (note == null || note.isEmpty) return;
    await _run('director-close', {'note': note});
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: hostelAppBar(
        '${_c['code'] ?? 'Complaint'}',
        subtitle: _c.isEmpty ? null : HostelLabels.category('${_c['category']}'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: HostelPage(
        maxWidth: 820,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: HostelColors.chefYellow))
          : _c.isEmpty
              ? const HostelEmpty(icon: Icons.error_outline_rounded, title: 'Complaint not found')
              : RefreshIndicator(
                  color: Colors.black,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                    children: [
                      _header(),
                      const SizedBox(height: 12),
                      _studentCard(),
                      if (_worker.isNotEmpty || '${_c['repairNote'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _repairCard(),
                      ],
                      if (asMapOf(_c['wardenReport'])['cause'] != null &&
                          '${asMapOf(_c['wardenReport'])['cause']}'.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _wardenCard(),
                      ],
                      if (_c['rating'] != null) ...[
                        const SizedBox(height: 12),
                        _ratingCard(),
                      ],
                      const SizedBox(height: 12),
                      _actions(),
                      const SizedBox(height: 18),
                      _timeline(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: GoogleFonts.poppins(color: HostelColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
      );

  Widget _header() {
    final photo = '${_c['photoUrl'] ?? ''}';
    final desc = '${_c['description'] ?? ''}';
    return HostelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              HostelChip(HostelLabels.status(_status), color: HostelLabels.statusColor(_status)),
              if (_level == 'warden') const HostelChip('At warden', color: HostelColors.purple),
              if (_level == 'director') const HostelChip('At director', color: HostelColors.red),
              HostelChip(
                _isOpen ? '${hoursOpen(_c['createdAt'])} h open' : dateTimeText(_c['createdAt']),
                color: HostelColors.textSecondary,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_c['title'] ?? ''}',
            style: GoogleFonts.poppins(color: HostelColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc, style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 13, height: 1.45)),
          ],
          if (photo.isNotEmpty) ...[
            const SizedBox(height: 12),
            _photo(photo),
          ],
        ],
      ),
    );
  }

  Widget _photo(String url) {
    return GestureDetector(
      onTap: () => Get.dialog(
        Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(10),
          child: InteractiveViewer(child: Image.network(url)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 170,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 60,
            color: HostelColors.background,
            alignment: Alignment.center,
            child: Text('Photo not loading', style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ),
      ),
    );
  }

  Widget _studentCard() {
    final phone = '${_c['studentPhone'] ?? ''}';
    return HostelCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: HostelColors.chefYellow.withValues(alpha: 0.25),
            child: const Icon(Icons.person_rounded, color: Color(0xFF8A6A00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_c['studentName'] ?? ''}',
                  style: GoogleFonts.poppins(color: HostelColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Block ${_c['hostelblock'] ?? '-'} • Room ${_c['room'] ?? '-'}',
                  style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton.filled(
              onPressed: () => callNumber(phone),
              style: IconButton.styleFrom(backgroundColor: HostelColors.green),
              icon: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _repairCard() {
    final note = '${_c['repairNote'] ?? ''}';
    final photo = '${_c['repairPhotoUrl'] ?? ''}';
    return HostelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Repair'),
          if (_worker.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.engineering_rounded, size: 20, color: HostelColors.greyBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_worker['name']} • ${StaffSession.tradeName('${_worker['trade'] ?? ''}')}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if ('${_worker['phone'] ?? ''}'.isNotEmpty && !_isMine)
                  TextButton.icon(
                    onPressed: () => callNumber('${_worker['phone']}'),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: const Text('Call'),
                  ),
              ],
            ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note, style: GoogleFonts.poppins(fontSize: 13, color: HostelColors.textPrimary)),
            Text(dateTimeText(_c['repairedAt']), style: GoogleFonts.poppins(fontSize: 11, color: HostelColors.textSecondary)),
          ],
          if (photo.isNotEmpty) ...[
            const SizedBox(height: 10),
            _photo(photo),
          ],
        ],
      ),
    );
  }

  Widget _wardenCard() {
    final r = asMapOf(_c['wardenReport']);
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 12.5, color: HostelColors.textPrimary, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: value),
              ],
            ),
          ),
        );
    return HostelCard(
      border: HostelColors.purple.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Warden report — ${r['wardenName'] ?? ''}'),
          line('Reason', '${r['cause'] ?? ''}'),
          line('Action', '${r['actionTaken'] ?? ''}'),
          if ('${r['solution'] ?? ''}'.isNotEmpty) line('Solution', '${r['solution']}'),
          if ('${_c['directorNote'] ?? ''}'.isNotEmpty) line('Director', '${_c['directorNote']}'),
        ],
      ),
    );
  }

  Widget _ratingCard() {
    final rating = (_c['rating'] is num) ? (_c['rating'] as num).toInt() : 0;
    final comment = '${_c['studentComment'] ?? ''}';
    return HostelCard(
      child: Row(
        children: [
          ...List.generate(
            5,
            (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: HostelColors.chefYellow, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              comment.isEmpty ? 'Student rating' : comment,
              style: GoogleFonts.poppins(fontSize: 12.5, color: HostelColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String text, IconData icon, VoidCallback onTap, {Color color = HostelColors.chefYellow, Color fg = Colors.black}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(text, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _actions() {
    final buttons = <Widget>[];
    final isHead = StaffSession.isHead;

    if (_role == 'worker') {
      if (['open', 'reopened'].contains(_status)) {
        buttons.add(_button("Accept — I'm going", Icons.handshake_rounded, _accept));
      }
      if (_isMine && ['in_progress', 'reopened'].contains(_status)) {
        buttons.add(_button('Mark repaired', Icons.check_circle_rounded, _repaired, color: HostelColors.green, fg: Colors.white));
      }
    }

    if (isHead && _isOpen) {
      buttons.add(_button(_worker.isEmpty ? 'Assign to worker' : 'Change worker', Icons.engineering_rounded, _assign));
      buttons.add(_button('Mark repaired', Icons.check_circle_rounded, _repaired, color: HostelColors.green, fg: Colors.white));
    }

    if (_role == 'warden' && _level != 'team' && _status != 'closed') {
      buttons.add(_button('Write warden report', Icons.edit_note_rounded, _wardenReport, color: HostelColors.purple, fg: Colors.white));
    }

    if (_role == 'director' && _status != 'closed') {
      buttons.add(_button('Final close', Icons.gavel_rounded, _directorClose, color: HostelColors.textPrimary, fg: Colors.white));
    }

    if (_status != 'closed') {
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _note,
            style: OutlinedButton.styleFrom(
              foregroundColor: HostelColors.textPrimary,
              side: const BorderSide(color: HostelColors.borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.sticky_note_2_outlined, size: 19),
            label: Text('Add note', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final b in buttons) ...[b, const SizedBox(height: 8)],
      ],
    );
  }

  String _who(String role) {
    final trade = StaffSession.tradeName(role);
    return trade != role ? trade : (role == 'student' ? 'Student' : StaffSession.roleName(role));
  }

  Widget _timeline() {
    final steps = asMapList(_c['timeline']).reversed.toList();
    if (steps.isEmpty) return const SizedBox.shrink();
    return HostelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('History'),
          for (int i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: i == 0 ? HostelColors.chefYellow : HostelColors.borderColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i != steps.length - 1) Container(width: 2, height: 42, color: HostelColors.borderColor),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${steps[i]['note'] ?? steps[i]['action'] ?? ''}',
                          style: GoogleFonts.poppins(fontSize: 12.5, color: HostelColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${steps[i]['byName'] ?? ''}${'${steps[i]['byRole'] ?? ''}'.isEmpty ? '' : ' (${_who('${steps[i]['byRole']}')})'} • ${dateTimeText(steps[i]['at'])}',
                          style: GoogleFonts.poppins(fontSize: 10.5, color: HostelColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
