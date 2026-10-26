// =====================================================================
// BANK STATEMENT CHECK
// Admin uploads the bank / Vyapar statement (Excel or CSV).
// The server reads every UPI credit (UTR + amount) and checks each
// student's screenshot against it. Edited / fake screenshots show
// "NOT in bank statement" and cannot be approved by mistake.
// =====================================================================
import 'dart:convert';

import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../apis/api_endpoints.dart';

/// Bank URLs — built from your existing ApiEndpoints, nothing to add there.
class BankApi {
  static String get _admin =>
      ApiEndpoints.paymentSubmissions.replaceFirst(RegExp(r'/payment-submissions$'), '');
  static String get statements => '$_admin/bank-statements';
  static String get unclaimed => '$_admin/bank-transactions/unclaimed';
  static String get approveVerified => '${ApiEndpoints.paymentSubmissions}/approve-verified';
}

class _BC {
  static const primary = Color(0xFFFFC800);
  static const primaryDark = Color(0xFF9A7600);
  static const bg = Color(0xFFF6F8FC);
  static const border = Color(0xFFE5EAF2);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFEAF8EF);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFFEEEE);
  static const amber = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFFF7E6);
}

class BankStatementScreen extends StatefulWidget {
  const BankStatementScreen({super.key});

  @override
  State<BankStatementScreen> createState() => _BankStatementScreenState();
}

class _BankStatementScreenState extends State<BankStatementScreen> {
  bool _loading = true;
  bool _uploading = false;
  bool _approving = false;
  String? _lastMessage;
  bool _lastOk = true;

  Map<String, dynamic> _summary = {};
  List<dynamic> _uploads = [];
  List<dynamic> _unclaimed = [];
  int _totalCredits = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse(BankApi.statements)),
        http.get(Uri.parse(BankApi.unclaimed)),
      ]);
      final a = jsonDecode(results[0].body);
      final b = jsonDecode(results[1].body);
      if (!mounted) return;
      setState(() {
        if (a['success'] == true) {
          _summary = Map<String, dynamic>.from(a['summary'] ?? {});
          _uploads = List<dynamic>.from(a['uploads'] ?? []);
          _totalCredits = ((a['totalCredits'] ?? 0) as num).toInt();
        }
        if (b['success'] == true) _unclaimed = List<dynamic>.from(b['transactions'] ?? []);
      });
    } catch (_) {
      _snack('Connection error. Check the server.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _snack('Could not read the file. Please try again.', error: true);
      return;
    }
    if (bytes.length > 7 * 1024 * 1024) {
      _snack('File is too big (max 7 MB). Download a shorter date range.', error: true);
      return;
    }

    setState(() => _uploading = true);
    try {
      final res = await http.post(
        Uri.parse(BankApi.statements),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fileName': file.name, 'base64': base64Encode(bytes)}),
      );
      final d = jsonDecode(res.body);
      setState(() {
        _lastOk = res.statusCode == 200 && d['success'] == true;
        _lastMessage = d['message']?.toString() ?? (_lastOk ? 'Done' : 'Upload failed');
      });
      if (_lastOk) await _load();
    } catch (_) {
      setState(() {
        _lastOk = false;
        _lastMessage = 'Connection error. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _approveAll() async {
    setState(() => _approving = true);
    try {
      final res = await http.post(
        Uri.parse(BankApi.approveVerified),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      );
      final d = jsonDecode(res.body);
      final failed = List<dynamic>.from(d['failed'] ?? []);
      _snack(
        '${d['message'] ?? 'Done'}${failed.isNotEmpty ? ' ${failed.length} need manual check (see Pending tab).' : ''}',
        error: res.statusCode != 200,
      );
      await _load();
    } catch (_) {
      _snack('Connection error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? _BC.red : _BC.text,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 5 : 3),
    ));
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BC.bg,
      appBar: AppBar(
        backgroundColor: _BC.primary,
        surfaceTintColor: _BC.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: _BC.text),
        title: Text('Bank Statement Check',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _BC.text)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: _BC.text),
          ),
        ],
      ),
      body: _loading && _uploads.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _BC.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _uploadCard(),
                          const SizedBox(height: 14),
                          _summaryCard(),
                          const SizedBox(height: 14),
                          _unclaimedCard(),
                          const SizedBox(height: 14),
                          _historyCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _box({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _BC.border),
          boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: child,
      );

  Widget _title(String t, {IconData? icon}) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: _BC.primaryDark, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15.5)),
          ),
        ],
      );

  Widget _uploadCard() {
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Upload bank / Vyapar statement', icon: Icons.upload_file_rounded),
          const SizedBox(height: 8),
          Text(
            'Screenshots can be edited, your bank statement cannot. Download the statement of the '
            'account where students pay (Excel .xlsx / .xls or CSV — not PDF) and upload it here. '
            'Every UTR is matched automatically.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: _BC.muted, height: 1.45),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _BC.amberSoft, borderRadius: BorderRadius.circular(10)),
            child: Text(
              'Tip: upload once every day (or before approving). You can upload the same days again — '
              'old entries are not counted twice.',
              style: GoogleFonts.poppins(fontSize: 11.5, color: _BC.amber, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _BC.text))
                  : const Icon(Icons.attach_file_rounded),
              label: Text(_uploading ? 'Reading statement…' : 'Choose statement file',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _BC.primary,
                foregroundColor: _BC.text,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_lastMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _lastOk ? _BC.greenSoft : _BC.redSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_lastOk ? Icons.check_circle_rounded : Icons.error_rounded,
                      size: 18, color: _lastOk ? _BC.green : _BC.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_lastMessage!,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, color: _lastOk ? _BC.green : _BC.red, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard() {
    int n(String k) => ((_summary[k] ?? 0) as num).toInt();
    final verified = n('verified');
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Pending screenshots vs bank', icon: Icons.fact_check_rounded),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat('In bank ✓', verified, _BC.green, _BC.greenSoft),
              _stat('Not in bank', n('not_found'), _BC.red, _BC.redSoft),
              _stat('Less amount', n('amount_low'), _BC.red, _BC.redSoft),
              _stat('Not checked', n('not_checked'), _BC.muted, const Color(0xFFF1F3F7)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: verified == 0 || _approving ? null : _approveAll,
              icon: _approving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.done_all_rounded),
              label: Text(
                verified == 0 ? 'No bank-verified payments waiting' : 'Approve all $verified bank-verified',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _BC.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"Not in bank" requests are in the Issues tab — reject them. '
            '"Not checked" means the statement for that day is not uploaded yet.',
            style: GoogleFonts.poppins(fontSize: 11.5, color: _BC.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color fg, Color bg) => Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      );

  Widget _unclaimedCard() {
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Money received, no screenshot yet (${_unclaimed.length})',
              icon: Icons.account_balance_wallet_rounded),
          const SizedBox(height: 6),
          Text(
            'These UPI credits are in your bank but no student has uploaded that UTR. '
            'Use Student Finance → manual entry if you know who paid.',
            style: GoogleFonts.poppins(fontSize: 11.5, color: _BC.muted, height: 1.4),
          ),
          const SizedBox(height: 8),
          if (_unclaimed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_totalCredits == 0 ? 'Upload a statement to see this.' : 'All credits are claimed. 👍',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: _BC.muted)),
            )
          else
            ..._unclaimed.take(50).map((t) {
              final m = Map<String, dynamic>.from(t);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: _BC.greenSoft,
                  child: Icon(Icons.currency_rupee_rounded, size: 16, color: _BC.green),
                ),
                title: Text('₹${m['amount']} · UTR ${m['utr']}',
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700)),
                subtitle: Text('${m['txnDay'] ?? ''}  ${m['narration'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11, color: _BC.muted)),
                trailing: IconButton(
                  tooltip: 'Copy UTR',
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${m['utr']}'));
                    _snack('UTR copied');
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Uploaded statements', icon: Icons.history_rounded),
          const SizedBox(height: 4),
          Text('$_totalCredits UPI credits saved in total',
              style: GoogleFonts.poppins(fontSize: 11.5, color: _BC.muted)),
          const SizedBox(height: 6),
          if (_uploads.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No statement uploaded yet.',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: _BC.muted)),
            )
          else
            ..._uploads.map((u) {
              final m = Map<String, dynamic>.from(u);
              final at = DateTime.tryParse('${m['createdAt'] ?? ''}');
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: _BC.primaryDark),
                title: Text('${m['fileName'] ?? 'statement'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${m['fromDay'] ?? '?'} → ${m['toDay'] ?? '?'} · ${m['credits'] ?? 0} credits (${m['added'] ?? 0} new)'
                  '${at != null ? ' · ${DateFormat('d MMM, h:mm a').format(at.toLocal())}' : ''}',
                  style: GoogleFonts.poppins(fontSize: 11, color: _BC.muted),
                ),
              );
            }),
        ],
      ),
    );
  }
}