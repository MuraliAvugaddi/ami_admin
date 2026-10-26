import 'dart:async';

import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// SOS ALARM — opens by itself when a student presses SOS.
// Alarm keeps ringing until someone presses "I'm going".
// ============================================================

class SosAlarmScreen extends StatefulWidget {
  final String sosId;

  const SosAlarmScreen({super.key, required this.sosId});

  @override
  State<SosAlarmScreen> createState() => _SosAlarmScreenState();
}

class _SosAlarmScreenState extends State<SosAlarmScreen> with SingleTickerProviderStateMixin {
  final HostelStaffService _service = HostelStaffService();
  late final AnimationController _pulse;

  Map<String, dynamic> _sos = {};
  bool _loading = true;
  bool _busy = false;
  Timer? _timer;

  HostelStaffController? get _staff =>
      Get.isRegistered<HostelStaffController>() ? Get.find<HostelStaffController>() : null;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _service.sosById(widget.sosId);
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) _sos = asMapOf(res['sos']);
      _loading = false;
    });
  }

  String get _status => '${_sos['status'] ?? 'active'}';

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _going() async {
    setState(() => _busy = true);
    _staff?.silence(widget.sosId);
    final res = await _service.sosAction(widget.sosId, 'going');
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      setState(() => _sos = asMapOf(res['sos']));
    } else {
      showResult(res);
    }
  }

  Future<void> _handled() async {
    final note = await askText(
      'Emergency handled?',
      hint: 'What happened? (e.g. Took student to hospital, snake removed)',
      ok: 'Mark handled',
    );
    if (note == null) return;
    setState(() => _busy = true);
    final res = await _service.sosAction(widget.sosId, 'handled', {'note': note});
    if (!mounted) return;
    setState(() => _busy = false);
    _staff?.silence(widget.sosId);
    _staff?.checkSos();
    if (res['success'] == true) {
      Get.back();
      showResult(res, okText: 'SOS closed');
    } else {
      showResult(res);
    }
  }

  void _close() {
    _staff?.silence(widget.sosId);
    Get.back();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final active = _status == 'active';
    final handled = _status == 'handled';

    return PopScope(
      canPop: !active,
      child: Scaffold(
        backgroundColor: active ? HostelColors.sosRed : HostelColors.background,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    _topBar(active),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Column(
                          children: [
                            _bigIcon(active),
                            const SizedBox(height: 16),
                            Text(
                              HostelLabels.sos('${_sos['type']}'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: active ? Colors.white : HostelColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              agoText(_sos['createdAt']),
                              style: GoogleFonts.poppins(
                                color: active ? Colors.white70 : HostelColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _studentCard(),
                            const SizedBox(height: 12),
                            if (!active) _statusCard(handled),
                          ],
                        ),
                      ),
                    ),
                    if (!handled) _bottomButtons(active),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _topBar(bool active) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _close,
            icon: Icon(Icons.close_rounded, color: active ? Colors.white : Colors.black),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active ? Colors.white24 : HostelColors.chefYellow,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '${_sos['code'] ?? 'SOS'}',
              style: GoogleFonts.poppins(
                color: active ? Colors.white : Colors.black,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _bigIcon(bool active) {
    final circle = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: active ? Colors.white : HostelColors.sosRed.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.sos_rounded, size: 64, color: HostelColors.sosRed),
    );
    if (!active) return circle;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Container(
        padding: EdgeInsets.all(10 + _pulse.value * 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12 + _pulse.value * 0.1),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
      child: circle,
    );
  }

  Widget _studentCard() {
    final phone = '${_sos['studentPhone'] ?? ''}';
    final father = '${_sos['fatherPhone'] ?? ''}';
    final block = '${_sos['hostelblock'] ?? ''}';
    final room = '${_sos['room'] ?? ''}';
    final note = '${_sos['note'] ?? ''}';

    return HostelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_sos['studentName'] ?? 'Student'}',
            style: GoogleFonts.poppins(
              color: HostelColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: HostelColors.sosRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [if (block.isNotEmpty) 'Block $block', if (room.isNotEmpty) 'Room $room'].join(' • '),
                  style: GoogleFonts.poppins(
                    color: HostelColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$note"',
              style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _callButton('Student', phone, HostelColors.green)),
              const SizedBox(width: 10),
              Expanded(child: _callButton('Parent', father, HostelColors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _callButton(String label, String phone, Color color) {
    final enabled = phone.trim().isNotEmpty;
    return OutlinedButton.icon(
      onPressed: enabled ? () => callNumber(phone) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: enabled ? color : HostelColors.borderColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.call_rounded, size: 18),
      label: Text(
        enabled ? 'Call $label' : 'No $label no.',
        style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusCard(bool handled) {
    final color = handled ? HostelColors.green : HostelColors.orange;
    return HostelCard(
      border: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(handled ? Icons.check_circle_rounded : Icons.directions_run_rounded, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  handled ? 'Handled by ${_sos['handledName']}' : '${_sos['goingName']} is on the way',
                  style: GoogleFonts.poppins(
                    color: HostelColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  handled
                      ? '${_sos['handledNote'] ?? ''}'
                      : 'Started ${agoText(_sos['goingAt'])}',
                  style: GoogleFonts.poppins(color: HostelColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButtons(bool active) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _busy ? null : (active ? _going : _handled),
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? Colors.white : HostelColors.green,
            foregroundColor: active ? HostelColors.sosRed : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(
                  active ? "I'M GOING — STOP ALARM" : 'Mark as handled',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}
