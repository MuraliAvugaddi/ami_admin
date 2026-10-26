// =====================================================================
// Shown at the top of "Record / Edit payment" for ONE student.
// • Screenshots this student uploaded (pending) → Approve / Reject here
// • Warnings: duplicate UTR, wrong amount, not paid to Chef, old date,
//   NOT in bank statement …
// • Recently rejected screenshots with the reason
// Approve saves UTR + date + screenshot for every month of the plan.
// =====================================================================
import 'dart:convert';

import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:ami_admin/screens/student_receipts_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../apis/api_endpoints.dart';

class _P {
  static const primaryDark = Color(0xFF9A7600);
  static const primarySoft = Color(0xFFFFF6CC);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE5EAF2);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFEAF8EF);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFFEEEE);
  static const amber = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFFF7E6);
  static const blue = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFEFF4FF);
}

const Map<String, String> _flagText = {
  'DUPLICATE_UTR': 'Duplicate UTR',
  'AMOUNT_MISMATCH': 'Wrong / less amount',
  'AMOUNT_NOT_FOUND': 'Amount not readable',
  'PAYEE_MISMATCH': 'Not paid to Ami Hostlers',
  'DATE_OLD': 'Old screenshot',
  'DATE_NOT_FOUND': 'Date not readable',
  'UTR_NOT_IN_IMAGE': 'UTR not in screenshot',
  'UTR_EDITED': 'Student changed the UTR',
};

const List<String> _rejectReasons = [
  'Wrong amount paid',
  'Payment not made to Ami Hostlers',
  'Payment not received in our bank',
  'Old or reused screenshot',
  'UTR number not matching',
  'Screenshot is unclear, please upload again',
];

String _money(num v) => NumberFormat.decimalPattern('en_IN').format(v.round());
String _date(dynamic v, [String p = 'd MMM, h:mm a']) {
  final d = DateTime.tryParse('${v ?? ''}');
  return d == null ? '' : DateFormat(p).format(d.toLocal());
}

class StudentPaymentRequestsPanel extends StatefulWidget {
  final String userId;

  /// Called after approve / reject (refresh your lists).
  final VoidCallback? onChanged;

  const StudentPaymentRequestsPanel({super.key, required this.userId, this.onChanged});

  @override
  State<StudentPaymentRequestsPanel> createState() => _StudentPaymentRequestsPanelState();
}

class _StudentPaymentRequestsPanelState extends State<StudentPaymentRequestsPanel> {
  bool _loading = true;
  bool _busy = false;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _rejected = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.studentReceipts(widget.userId)));
      final d = jsonDecode(res.body);
      if (!mounted) return;
      final subs = List<Map<String, dynamic>>.from(
          (d['submissions'] ?? const []).map((e) => Map<String, dynamic>.from(e)));
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      setState(() {
        _pending = subs.where((s) => s['status'] == 'pending').toList();
        _rejected = subs
            .where((s) =>
                s['status'] == 'rejected' &&
                (DateTime.tryParse('${s['createdAt'] ?? ''}')?.isAfter(monthAgo) ?? false))
            .take(3)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? _P.red : _P.text,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 5 : 3),
    ));
  }

  Future<Map<String, dynamic>?> _post(String url, Map<String, dynamic> body) async {
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return Map<String, dynamic>.from(jsonDecode(res.body))..['_status'] = res.statusCode;
    } catch (_) {
      _snack('Connection error. Please try again.', error: true);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------------
  // APPROVE
  // ------------------------------------------------------------------
  Future<void> _approve(Map<String, dynamic> s) async {
    final utrCtrl = TextEditingController(text: '${s['utr'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Approve this payment?', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${List<String>.from(s['months'] ?? const []).join(', ')} · ₹${_money((s['expectedAmount'] ?? 0) as num)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: utrCtrl,
                maxLength: 12,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'UTR (correct it if needed)',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              Text('UTR, payment date and the screenshot are saved for every month and in Excel.',
                  style: GoogleFonts.poppins(fontSize: 11, color: _P.muted)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: _P.muted))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: _P.green, foregroundColor: Colors.white, elevation: 0),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final url = ApiEndpoints.approveSubmission('${s['_id']}');
    final body = {'utr': utrCtrl.text.trim()};
    var r = await _post(url, body);
    if (r == null) return;

    if (r['code'] == 'BANK_NOT_VERIFIED') {
      if (!mounted) return;
      final force = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.gpp_maybe_rounded, color: _P.red, size: 38),
          title: Text('Money not confirmed by bank',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Text(
            '${r!['message'] ?? ''}\n\nApprove only if you checked your bank / Vyapar app yourself.',
            style: GoogleFonts.poppins(fontSize: 13, height: 1.45),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: ElevatedButton.styleFrom(backgroundColor: _P.text, foregroundColor: Colors.white, elevation: 0),
              child: Text("Don't approve", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('I checked — approve',
                  style: GoogleFonts.poppins(color: _P.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      if (force != true) return;
      r = await _post(url, {...body, 'force': true});
      if (r == null) return;
    }

    if (r['success'] == true) {
      _snack('✅ ${r['message'] ?? 'Approved'} Receipt sent to the student.');
      widget.onChanged?.call();
      await _load();
    } else {
      _snack('${r['message'] ?? 'Could not approve.'}', error: true);
    }
  }

  // ------------------------------------------------------------------
  // REJECT
  // ------------------------------------------------------------------
  Future<void> _reject(Map<String, dynamic> s) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Reject screenshot', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The student gets a notification with this reason.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _P.muted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _rejectReasons
                      .map((t) => ChoiceChip(
                            label: Text(t, style: GoogleFonts.poppins(fontSize: 11)),
                            selected: reasonCtrl.text == t,
                            selectedColor: _P.redSoft,
                            onSelected: (_) => setD(() => reasonCtrl.text = t),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  onChanged: (_) => setD(() {}),
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(color: _P.muted))),
            ElevatedButton(
              onPressed: reasonCtrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, reasonCtrl.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: _P.red, foregroundColor: Colors.white, elevation: 0),
              child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (reason == null || reason.isEmpty) return;

    final r = await _post(ApiEndpoints.rejectSubmission('${s['_id']}'), {'reason': reason});
    if (r == null) return;
    if (r['success'] == true) {
      _snack('Rejected. The student was notified.');
      widget.onChanged?.call();
      await _load();
    } else {
      _snack('${r['message'] ?? 'Could not reject.'}', error: true);
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: LinearProgressIndicator(minHeight: 2, color: _P.primaryDark),
      );
    }
    if (_pending.isEmpty && _rejected.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFC), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.image_not_supported_outlined, size: 16, color: _P.muted),
            const SizedBox(width: 8),
            Text('No payment screenshot waiting from this student.',
                style: GoogleFonts.poppins(fontSize: 11.5, color: _P.muted)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pending.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, size: 17, color: _P.blue),
              const SizedBox(width: 6),
              Text('Screenshot waiting for approval (${_pending.length})',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13, color: _P.text)),
            ],
          ),
          const SizedBox(height: 8),
          ..._pending.map(_pendingCard),
        ],
        if (_rejected.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Recently rejected', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12, color: _P.muted)),
          const SizedBox(height: 4),
          ..._rejected.map(_rejectedRow),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _pendingCard(Map<String, dynamic> s) {
    final detected = Map<String, dynamic>.from(s['detected'] ?? {});
    final flags = List<String>.from(s['flags'] ?? const []);
    final months = List<String>.from(s['months'] ?? const []);
    final bank = Map<String, dynamic>.from(s['bank'] ?? {});
    final expected = (s['expectedAmount'] ?? 0) as num;
    final fine = (s['fineAmount'] ?? 0) as num;
    final detAmount = detected['amount'] as num?;
    final url = '${s['screenshotUrl'] ?? ''}';
    final bad = flags.isNotEmpty || ['not_found', 'amount_low'].contains(bank['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bad ? const Color(0xFFFFFBF5) : _P.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bad ? const Color(0xFFF5C99B) : const Color(0xFFC9D8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: url.isEmpty ? null : () => showScreenshot(context, url),
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url.isEmpty
                      ? Container(width: 64, height: 112, color: const Color(0xFFF3F4F6))
                      : Image.network(url,
                          width: 64,
                          height: 112,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, st) =>
                              Container(width: 64, height: 112, color: const Color(0xFFF3F4F6))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${months.join(', ')}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(
                      '${s['planMonths']} month${s['planMonths'] == 1 ? '' : 's'} · ₹${_money(expected)}'
                      '${fine > 0 ? ' (incl. fine ₹${_money(fine)})' : ''} · ${_date(s['createdAt'])}',
                      style: GoogleFonts.poppins(fontSize: 11, color: _P.muted),
                    ),
                    const SizedBox(height: 6),
                    _info('UTR', '${s['utr'] ?? ''}',
                        ok: !flags.contains('DUPLICATE_UTR') && !flags.contains('UTR_NOT_IN_IMAGE'), copy: true),
                    _info('Amount', detAmount == null ? 'Not read' : '₹${_money(detAmount)}',
                        ok: detAmount != null && detAmount.round() >= expected.round()),
                    _info('Payee', detected['payeeMatched'] == true ? 'Ami Hostlers ✓' : 'Not matched',
                        ok: detected['payeeMatched'] == true),
                    _info('Paid on', detected['paidOn'] == null ? 'Not read' : _date(detected['paidOn'], 'd MMM yyyy'),
                        ok: detected['paidOn'] != null && !flags.contains('DATE_OLD')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _bankBox(bank, expected),
          if (flags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: flags
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: f == 'DUPLICATE_UTR' ? _P.redSoft : _P.amberSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('⚠ ${_flagText[f] ?? f}',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: f == 'DUPLICATE_UTR' ? _P.red : _P.amber)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _reject(s),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _P.red,
                    side: const BorderSide(color: Color(0xFFF5B5B5)),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _approve(s),
                  icon: _busy
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rejectedRow(Map<String, dynamic> s) {
    final dup = s['autoRejected'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: _P.redSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(dup ? Icons.copy_all_rounded : Icons.cancel_rounded, size: 16, color: _P.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${List<String>.from(s['months'] ?? const []).join(', ')} · UTR ${s['utr'] ?? ''}\n${s['rejectReason'] ?? ''}',
              style: GoogleFonts.poppins(fontSize: 11, color: _P.red, height: 1.35),
            ),
          ),
          if ('${s['screenshotUrl'] ?? ''}'.isNotEmpty)
            IconButton(
              tooltip: 'View screenshot',
              visualDensity: VisualDensity.compact,
              onPressed: () => showScreenshot(context, '${s['screenshotUrl']}'),
              icon: const Icon(Icons.image_outlined, size: 18, color: _P.red),
            ),
        ],
      ),
    );
  }

  Widget _bankBox(Map<String, dynamic> bank, num expected) {
    final st = '${bank['status'] ?? 'not_checked'}';
    late Color fg, bg;
    late IconData icon;
    late String text;
    switch (st) {
      case 'verified':
        fg = _P.green;
        bg = _P.greenSoft;
        icon = Icons.verified_rounded;
        text = 'In bank statement · ₹${bank['bankAmount']} received';
        break;
      case 'amount_low':
        fg = _P.red;
        bg = _P.redSoft;
        icon = Icons.money_off_rounded;
        text = 'Bank received only ₹${bank['bankAmount']} (needs ₹${_money(expected)})';
        break;
      case 'not_found':
        fg = _P.red;
        bg = _P.redSoft;
        icon = Icons.gpp_bad_rounded;
        text = 'NOT in bank statement — may be edited / fake';
        break;
      default:
        fg = _P.muted;
        bg = const Color(0xFFF1F3F7);
        icon = Icons.hourglass_top_rounded;
        text = 'Not checked with bank yet';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value, {required bool ok, bool copy = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, size: 13, color: ok ? _P.green : _P.amber),
            const SizedBox(width: 5),
            SizedBox(width: 52, child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: _P.muted))),
            Expanded(
              child: InkWell(
                onTap: copy
                    ? () {
                        Clipboard.setData(ClipboardData(text: value));
                        _snack('UTR copied');
                      }
                    : null,
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: copy ? 0.4 : 0)),
              ),
            ),
          ],
        ),
      );
}