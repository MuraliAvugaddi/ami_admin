// =====================================================================
// Month-wise receipts of one student: UTR + screenshot for every month
// (August, September, October ...) plus all uploaded screenshots.
// Usage: showStudentReceipts(context, userId: id, name: 'Rahul');
// =====================================================================
import 'dart:convert';

import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../apis/api_endpoints.dart';

class ReceiptColors {
  static const primary = Color(0xFFFFC800);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE5EAF2);
  static const bg = Color(0xFFF6F8FC);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFEAF8EF);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFFEEEE);
  static const amber = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFFF7E6);
}

Future<void> showStudentReceipts(
  BuildContext context, {
  required String userId,
  required String name,
}) {
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: ReceiptColors.bg,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: StudentReceiptsView(userId: userId, name: name),
      ),
    ),
  );
}

/// Full-screen zoomable screenshot viewer.
void showScreenshot(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 6,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (c, child, p) => p == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: ReceiptColors.primary)),
                errorBuilder: (c, e, s) => const Center(
                  child: Text('Could not load image', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class StudentReceiptsView extends StatefulWidget {
  final String userId;
  final String name;
  const StudentReceiptsView({super.key, required this.userId, required this.name});

  @override
  State<StudentReceiptsView> createState() => _StudentReceiptsViewState();
}

class _StudentReceiptsViewState extends State<StudentReceiptsView> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _student = {};
  List<dynamic> _payments = [];
  List<dynamic> _submissions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.studentReceipts(widget.userId)));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _student = Map<String, dynamic>.from(data['student'] ?? {});
          _payments = List<dynamic>.from(data['payments'] ?? []);
          _submissions = List<dynamic>.from(data['submissions'] ?? []);
        });
      } else {
        setState(() => _error = data['message']?.toString() ?? 'Could not load receipts');
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}');
    return d == null ? '-' : DateFormat('d MMM yyyy').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: ReceiptColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Color(0xFF9A7600)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment receipts',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(
                      [
                        widget.name,
                        if ((_student['enrollmentNo'] ?? '').toString().isNotEmpty) _student['enrollmentNo'],
                        if (_student['room'] != null) 'Room ${_student['room']}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, color: ReceiptColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: ReceiptColors.primary))
              : _error != null
                  ? Center(child: Text(_error!, style: GoogleFonts.poppins(color: ReceiptColors.muted)))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _accessBanner(),
                        const SizedBox(height: 14),
                        _sectionTitle('Paid months', _payments.length),
                        const SizedBox(height: 8),
                        if (_payments.isEmpty)
                          _empty('No payments recorded yet.')
                        else
                          ..._payments.map((p) => _paymentTile(Map<String, dynamic>.from(p))),
                        const SizedBox(height: 18),
                        _sectionTitle('Uploaded screenshots', _submissions.length),
                        const SizedBox(height: 8),
                        if (_submissions.isEmpty)
                          _empty('This student has not uploaded any screenshot.')
                        else
                          ..._submissions.map((s) => _submissionTile(Map<String, dynamic>.from(s))),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _accessBanner() {
    final expiry = DateTime.tryParse('${_student['accessExpiresAt'] ?? ''}');
    final active = expiry != null && expiry.isAfter(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? ReceiptColors.greenSoft : ReceiptColors.redSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.verified_rounded : Icons.block_rounded,
              color: active ? ReceiptColors.green : ReceiptColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active
                  ? 'Mess access active till ${DateFormat('d MMMM yyyy').format(expiry!.toLocal())}'
                  : 'No active mess access',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? ReceiptColors.green : ReceiptColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, int n) => Row(
        children: [
          Text(t, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$n', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      );

  Widget _empty(String t) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ReceiptColors.border),
        ),
        child: Text(t, style: GoogleFonts.poppins(fontSize: 12.5, color: ReceiptColors.muted)),
      );

  Widget _thumb(String url) {
    if (url.isEmpty) {
      return Container(
        width: 56,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.payments_outlined, color: ReceiptColors.muted),
      );
    }
    return InkWell(
      onTap: () => showScreenshot(context, url),
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 56,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            width: 56,
            height: 72,
            color: const Color(0xFFF3F4F6),
            child: const Icon(Icons.broken_image_outlined, color: ReceiptColors.muted),
          ),
        ),
      ),
    );
  }

  Widget _paymentTile(Map<String, dynamic> p) {
    final utr = (p['transactionId'] ?? '').toString();
    final source = (p['source'] ?? '').toString();
    final mode = source == 'screenshot'
        ? 'UPI screenshot'
        : (p['method'] == 'offline' ? 'Manual / cash' : 'Online');
    final plan = (p['planMonths'] ?? 1) as num;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReceiptColors.border),
      ),
      child: Row(
        children: [
          _thumb((p['screenshotUrl'] ?? '').toString()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${p['month'] ?? ''}',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    Text('₹${p['amount'] ?? 0}',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w800, color: ReceiptColors.green)),
                  ],
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: utr.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: utr));
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            const SnackBar(content: Text('UTR copied')),
                          );
                        },
                  child: Text('UTR: ${utr.isEmpty ? 'Cash' : utr}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$mode · Paid ${_date(p['paidAt'])}${plan > 1 ? ' · ${plan.toInt()}-month plan' : ''}',
                  style: GoogleFonts.poppins(fontSize: 11, color: ReceiptColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _submissionTile(Map<String, dynamic> s) {
    final status = (s['status'] ?? 'pending').toString();
    final color = status == 'approved'
        ? ReceiptColors.green
        : status == 'rejected'
            ? ReceiptColors.red
            : ReceiptColors.amber;
    final months = List<String>.from(s['months'] ?? const []);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReceiptColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb((s['screenshotUrl'] ?? '').toString()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(months.join(', '),
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    Text(status.toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('₹${s['expectedAmount'] ?? 0} · UTR ${s['utr'] ?? ''} · ${_date(s['createdAt'])}',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: ReceiptColors.muted)),
                if ((s['rejectReason'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Reason: ${s['rejectReason']}',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: ReceiptColors.red)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
