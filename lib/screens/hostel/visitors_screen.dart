import 'dart:async';

import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ============================================================
// VISITOR REGISTER — people who scanned the gate QR
// ============================================================

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final HostelStaffService _service = HostelStaffService();
  final TextEditingController _search = TextEditingController();

  DateTime _date = DateTime.now();
  bool _insideOnly = false;
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  Timer? _debounce;
  Worker? _live;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<HostelStaffController>()) {
      _live = ever(Get.find<HostelStaffController>().changes, (_) => _load(silent: true));
    }
    _load();
  }

  @override
  void dispose() {
    _live?.dispose();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _service.visitors(
      date: _insideOnly ? '' : DateFormat('yyyy-MM-dd').format(_date),
      inside: _insideOnly,
      search: _search.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _list = asMapList(res['visitors']);
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d == null) return;
    setState(() {
      _date = d;
      _insideOnly = false;
    });
    _load();
  }

  Future<void> _checkout(Map<String, dynamic> v) async {
    final res = await _service.visitorAction('${v['_id']}', 'checkout');
    showResult(res, okText: 'Checked out');
    _load(silent: true);
  }

  Future<void> _flag(Map<String, dynamic> v) async {
    String note = '';
    if (v['flagged'] != true) {
      final text = await askText('Flag visitor', hint: 'Reason (e.g. Not allowed, misbehaved)', ok: 'Flag');
      if (text == null) return;
      note = text;
    }
    final res = await _service.visitorAction('${v['_id']}', 'flag', {'note': note});
    showResult(res);
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final inside = _list.where((v) => v['outAt'] == null).length;
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: hostelAppBar(
        'Visitor Register',
        subtitle: _insideOnly ? 'Inside right now' : DateFormat('EEE, d MMM yyyy').format(_date),
        actions: [
          IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_rounded)),
        ],
      ),
      body: HostelPage(
        maxWidth: 1100,
        child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 2),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HostelColors.borderColor),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 450), _load);
                  },
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search visitor, student, vehicle no…',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: HostelColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: HostelColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_list.length} visitors • $inside inside',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: HostelColors.textSecondary),
                    ),
                    const Spacer(),
                    Text('Inside only', style: GoogleFonts.poppins(fontSize: 12)),
                    Switch(
                      value: _insideOnly,
                      activeTrackColor: HostelColors.chefYellow,
                      onChanged: (v) {
                        setState(() => _insideOnly = v);
                        _load();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                          HostelEmpty(icon: Icons.badge_outlined, title: 'No visitors', subtitle: 'Gate entries will show here.'),
                        ])
                      : HostelResponsiveList(
                          itemCount: _list.length,
                          maxColumns: 2,
                          itemBuilder: (_, i) => _visitorCard(_list[i]),
                        ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _visitorCard(Map<String, dynamic> v) {
    final isInside = v['outAt'] == null;
    final overstay = v['overstay'] == true;
    final flagged = v['flagged'] == true;
    final photo = '${v['photoUrl'] ?? ''}';
    final vehicle = '${v['vehicleNumber'] ?? ''}';

    return HostelCard(
      padding: const EdgeInsets.all(12),
      border: flagged ? HostelColors.red : (overstay ? HostelColors.orange : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: photo.isEmpty
                    ? null
                    : () => Get.dialog(Dialog(
                          backgroundColor: Colors.black,
                          insetPadding: const EdgeInsets.all(10),
                          child: InteractiveViewer(child: Image.network(photo)),
                        )),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photo.isEmpty
                      ? Container(width: 54, height: 54, color: HostelColors.background, child: const Icon(Icons.person))
                      : Image.network(
                          photo,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(width: 54, height: 54, color: HostelColors.background, child: const Icon(Icons.person)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${v['name']}${'${v['relation'] ?? ''}'.isEmpty ? '' : ' (${v['relation']})'}',
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: HostelColors.textPrimary),
                    ),
                    Text(
                      'To meet ${v['studentName']}${'${v['studentRoom'] ?? ''}'.isEmpty ? '' : ' • Room ${v['studentRoom']}'}',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary),
                    ),
                    Text(
                      'In ${dateTimeText(v['inAt'])}${isInside ? '' : '  →  Out ${DateFormat('h:mm a').format(DateTime.parse('${v['outAt']}').toLocal())}'}',
                      style: GoogleFonts.poppins(fontSize: 11, color: HostelColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => callNumber('${v['phone']}'),
                icon: const Icon(Icons.call_rounded, color: HostelColors.green, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              HostelChip(isInside ? 'Inside' : 'Left', color: isInside ? HostelColors.teal : HostelColors.greyBlue),
              if (overstay) const HostelChip('Over time', color: HostelColors.orange, icon: Icons.timer_off_rounded),
              if (flagged) HostelChip('Flagged ${v['flagNote'] ?? ''}', color: HostelColors.red, icon: Icons.flag_rounded),
              if (v['peopleCount'] is num && (v['peopleCount'] as num) > 1)
                HostelChip('${v['peopleCount']} people', color: HostelColors.purple),
              if (vehicle.isNotEmpty) HostelChip(vehicle, color: HostelColors.blue, icon: Icons.directions_car_rounded),
              Text('${v['code']}', style: GoogleFonts.poppins(fontSize: 10.5, color: HostelColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isInside)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _checkout(v),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HostelColors.chefYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Check out', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              if (isInside) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _flag(v),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: flagged ? HostelColors.textPrimary : HostelColors.red,
                    side: const BorderSide(color: HostelColors.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(flagged ? 'Remove flag' : 'Flag', style: GoogleFonts.poppins(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
