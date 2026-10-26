// =====================================================================
// PAYMENT REQUESTS — students' UPI screenshots waiting for approval.
// Tabs: Pending · Issues (duplicate / wrong / NOT IN BANK) · Approved · Rejected
// Every request is checked against the uploaded bank statement:
//   ✅ In bank   ❌ Not in bank (edited / fake)   ⏳ Not checked yet
// Approve → UTR + date saved for every month of the plan, access extended,
// shows up automatically in the Excel export.
// =====================================================================
import 'dart:convert';

import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:ami_admin/screens/bank_statement_screen.dart';
import 'package:ami_admin/screens/student_receipts_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../apis/api_endpoints.dart';

class _PC {
  static const primary = Color(0xFFFFC800);
  static const primaryDark = Color(0xFF9A7600);
  static const primarySoft = Color(0xFFFFF6CC);
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

/// Readable text for each automatic flag.
const Map<String, String> _flagText = {
  'DUPLICATE_UTR': 'Duplicate UTR',
  'AMOUNT_MISMATCH': 'Wrong / less amount',
  'AMOUNT_NOT_FOUND': 'Amount not readable',
  'PAYEE_MISMATCH': 'Not paid to Ami Hostlers',
  'DATE_OLD': 'Old screenshot',
  'DATE_NOT_FOUND': 'Date not readable',
  'UTR_NOT_IN_IMAGE': 'UTR not in screenshot',
  'UTR_EDITED': 'Student edited UTR',
};

const List<String> _rejectReasons = [
  'Wrong amount paid',
  'Payment not made to Ami Hostlers',
  'Old or reused screenshot',
  'UTR number not visible / not matching',
  'Duplicate UTR — already used',
  'Screenshot is unclear, please upload again',
];

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['pending', 'issues', 'approved', 'rejected'];

  late final TabController _tab = TabController(length: _tabs.length, vsync: this);
  final _search = TextEditingController();

  final Map<String, List<dynamic>> _data = {};
  final Map<String, bool> _loading = {};
  Map<String, int> _counts = {};
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _load(_tabs[_tab.index]);
    });
    _refreshAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadCounts(), _load(_tabs[_tab.index], force: true)]);
  }

  Future<void> _loadCounts() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.paymentSubmissionCounts));
      final d = jsonDecode(res.body);
      if (res.statusCode == 200 && mounted) {
        setState(() => _counts = {
              for (final t in [..._tabs, 'verified']) t: ((d[t] ?? 0) as num).toInt(),
            });
      }
    } catch (_) {}
  }

  Future<void> _load(String status, {bool force = false}) async {
    if (!force && _data.containsKey(status)) return;
    setState(() => _loading[status] = true);
    try {
      final uri = Uri.parse(ApiEndpoints.paymentSubmissions).replace(queryParameters: {
        'status': status,
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      });
      final res = await http.get(uri);
      final d = jsonDecode(res.body);
      if (res.statusCode == 200 && d['success'] == true) {
        _data[status] = List<dynamic>.from(d['submissions'] ?? []);
      } else {
        _snack(d['message']?.toString() ?? 'Could not load requests', error: true);
      }
    } catch (_) {
      _snack('Connection error. Check the server.', error: true);
    } finally {
      if (mounted) setState(() => _loading[status] = false);
    }
  }

  void _reloadEverything() {
    _data.clear();
    _refreshAll();
  }

  // ------------------------------------------------------------------
  // APPROVE / REJECT
  // ------------------------------------------------------------------

  Future<void> _approve(Map<String, dynamic> s) async {
    final utrCtrl = TextEditingController(text: '${s['utr'] ?? ''}');
    final user = Map<String, dynamic>.from(s['userId'] ?? {});
    final months = List<String>.from(s['months'] ?? const []);
    final flags = List<String>.from(s['flags'] ?? const []);
    final bank = Map<String, dynamic>.from(s['bank'] ?? {});

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Approve payment?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user['name'] ?? 'Student'} · ₹${s['expectedAmount']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Months: ${months.join(', ')}',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: _PC.muted)),
              const SizedBox(height: 10),
              _bankBox(bank, expected: s['expectedAmount']),
              if (flags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _PC.amberSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'Warning: ${flags.map((f) => _flagText[f] ?? f).join(', ')}. Check the screenshot carefully before approving.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _PC.amber, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: utrCtrl,
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'UTR (correct it if needed)',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'UTR and payment date will be saved for every month and appear in the Excel report.',
                style: GoogleFonts.poppins(fontSize: 11, color: _PC.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: _PC.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _PC.green,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final id = s['_id'].toString();
    final url = ApiEndpoints.approveSubmission(id);
    final body = {'utr': utrCtrl.text.trim()};
    final r = await _post(id, url, body, quietOn409: true);

    // Bank does not confirm this payment → ask again, clearly
    if (r != null && r['code'] == 'BANK_NOT_VERIFIED') {
      final force = await _confirmWithoutBank(r['message']?.toString() ?? '');
      if (force == true) await _post(id, url, {...body, 'force': true});
    }
  }

  Future<bool?> _confirmWithoutBank(String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.gpp_maybe_rounded, color: _PC.red, size: 40),
        title: Text('Money not confirmed by bank',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            '$message\n\nScreenshots can be edited. Approve only if you have checked your bank / Vyapar app yourself and the money is there.',
            style: GoogleFonts.poppins(fontSize: 13, height: 1.45),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: ElevatedButton.styleFrom(
                backgroundColor: _PC.text, foregroundColor: Colors.white, elevation: 0),
            child: Text("Don't approve", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('I checked — approve anyway',
                style: GoogleFonts.poppins(color: _PC.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAllVerified() async {
    final n = _counts['verified'] ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Approve $n bank-verified payment${n == 1 ? '' : 's'}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'Only requests whose UTR and amount are found in your bank statement will be approved.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: _PC.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _PC.green, foregroundColor: Colors.white, elevation: 0),
            child: Text('Approve all', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) await _post('all', BankApi.approveVerified, {});
  }

  Future<void> _openBankScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BankStatementScreen()));
    _reloadEverything();
  }

  Future<void> _reject(Map<String, dynamic> s) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Reject screenshot',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The student will see this reason in the app.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _PC.muted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _rejectReasons
                      .map((r) => ChoiceChip(
                            label: Text(r, style: GoogleFonts.poppins(fontSize: 11.5)),
                            selected: reasonCtrl.text == r,
                            onSelected: (_) => setD(() => reasonCtrl.text = r),
                            selectedColor: _PC.redSoft,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
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
              child: Text('Cancel', style: GoogleFonts.poppins(color: _PC.muted)),
            ),
            ElevatedButton(
              onPressed: reasonCtrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, reasonCtrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _PC.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (reason == null || reason.isEmpty) return;

    await _post(
      s['_id'].toString(),
      ApiEndpoints.rejectSubmission(s['_id'].toString()),
      {'reason': reason},
    );
  }

  Future<Map<String, dynamic>?> _post(String id, String url, Map<String, dynamic> body,
      {bool quietOn409 = false}) async {
    setState(() => _busy.add(id));
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final d = Map<String, dynamic>.from(jsonDecode(res.body));
      if (res.statusCode == 200 && d['success'] == true) {
        _snack(d['message']?.toString() ?? 'Done');
        _reloadEverything();
      } else if (!(quietOn409 && d['code'] == 'BANK_NOT_VERIFIED')) {
        _snack(d['message']?.toString() ?? 'Action failed', error: true);
      }
      return d;
    } catch (_) {
      _snack('Connection error. Please try again.', error: true);
      return null;
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? _PC.red : _PC.text,
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
        backgroundColor: _PC.bg,
        appBar: AppBar(
          backgroundColor: _PC.primary,
          surfaceTintColor: _PC.primary,
          elevation: 0,
          title: Text('Payment Requests',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _PC.text)),
          iconTheme: const IconThemeData(color: _PC.text),
          actions: [
            TextButton.icon(
              onPressed: _openBankScreen,
              icon: const Icon(Icons.account_balance_rounded, color: _PC.text, size: 20),
              label: Text('Bank statement',
                  style: GoogleFonts.poppins(color: _PC.text, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _reloadEverything,
              icon: const Icon(Icons.refresh_rounded, color: _PC.text),
            ),
            const SizedBox(width: 6),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tab,
                isScrollable: MediaQuery.of(context).size.width < 520,
                labelColor: _PC.text,
                unselectedLabelColor: _PC.muted,
                indicatorColor: _PC.primaryDark,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  _tabLabel('Pending', _counts['pending'], _PC.amber),
                  _tabLabel('Issues', _counts['issues'], _PC.red),
                  _tabLabel('Approved', null, _PC.green),
                  _tabLabel('Rejected', null, _PC.red),
                ],
              ),
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _reloadEverything(),
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search name, enrollment, room, phone or UTR — press Enter',
                      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: _PC.muted),
                      prefixIcon: const Icon(Icons.search_rounded, color: _PC.primaryDark),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                _reloadEverything();
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _PC.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _PC.border),
                      ),
                    ),
                  ),
                ),
                if ((_counts['verified'] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                    child: Material(
                      color: _PC.greenSoft,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.verified_rounded, color: _PC.green),
                        title: Text(
                          '${_counts['verified']} payment${_counts['verified'] == 1 ? '' : 's'} confirmed by bank statement',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        trailing: ElevatedButton(
                          onPressed: _busy.contains('all') ? null : _approveAllVerified,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _PC.green, foregroundColor: Colors.white, elevation: 0),
                          child: Text('Approve all',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: _tabs.map(_list).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Tab _tabLabel(String text, int? count, Color color) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text('$count',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      );

  Widget _list(String status) {
    final loading = _loading[status] == true;
    final items = _data[status];
    if (loading && items == null) {
      return const Center(child: CircularProgressIndicator(color: _PC.primary));
    }
    if (items == null || items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(status, force: true),
        child: ListView(
          children: [
            const SizedBox(height: 90),
            Icon(
              status == 'pending' ? Icons.inbox_rounded : Icons.check_circle_outline_rounded,
              size: 56,
              color: const Color(0xFFCBD2DC),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                status == 'pending'
                    ? 'No screenshots waiting for approval'
                    : status == 'issues'
                        ? 'No duplicate or wrong screenshots'
                        : 'Nothing here yet',
                style: GoogleFonts.poppins(color: _PC.muted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadCounts();
        await _load(status, force: true);
      },
      child: LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth > 1050 ? 2 : 1;
        if (columns == 1) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _card(Map<String, dynamic>.from(items[i])),
            ),
          );
        }
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items
                .map((s) => SizedBox(
                      width: (c.maxWidth - 32 - 12) / 2,
                      child: _card(Map<String, dynamic>.from(s)),
                    ))
                .toList(),
          ),
        );
      }),
    );
  }

  Widget _card(Map<String, dynamic> s) {
    final user = Map<String, dynamic>.from(s['userId'] ?? {});
    final detected = Map<String, dynamic>.from(s['detected'] ?? {});
    final flags = List<String>.from(s['flags'] ?? const []);
    final months = List<String>.from(s['months'] ?? const []);
    final status = (s['status'] ?? 'pending').toString();
    final id = s['_id'].toString();
    final busy = _busy.contains(id);
    final expected = (s['expectedAmount'] ?? 0) as num;
    final detAmount = detected['amount'] as num?;
    final amountOk = detAmount != null && detAmount.round() >= expected.round();
    final paidOn = DateTime.tryParse('${detected['paidOn'] ?? ''}');
    final created = DateTime.tryParse('${s['createdAt'] ?? ''}');
    final dup = Map<String, dynamic>.from(s['duplicateOf'] ?? {});
    final url = (s['screenshotUrl'] ?? '').toString();
    final bank = Map<String, dynamic>.from(s['bank'] ?? {});
    final bankBad = status == 'pending' && ['not_found', 'amount_low'].contains(bank['status']);

    final statusColor = status == 'approved'
        ? _PC.green
        : status == 'rejected'
            ? _PC.red
            : _PC.amber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: bankBad
                ? _PC.red
                : flags.isNotEmpty
                    ? const Color(0xFFF5D0A9)
                    : _PC.border,
            width: bankBad ? 1.6 : 1),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screenshot
          InkWell(
            onTap: url.isEmpty ? null : () => showScreenshot(context, url),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url.isEmpty
                  ? Container(width: 96, height: 170, color: const Color(0xFFF3F4F6))
                  : Image.network(
                      url,
                      width: 96,
                      height: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, st) => Container(
                        width: 96,
                        height: 170,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.broken_image_outlined, color: _PC.muted),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: user['_id'] == null
                            ? null
                            : () => showStudentReceipts(context,
                                userId: user['_id'].toString(), name: '${user['name'] ?? ''}'),
                        child: Text('${user['name'] ?? 'Deleted student'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFFCBD2DC))),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 9.5, fontWeight: FontWeight.w800, color: statusColor)),
                    ),
                  ],
                ),
                Text(
                  [
                    user['enrollmentNo'],
                    if (user['room'] != null) 'Room ${user['room']}',
                    if (user['year'] != null) 'Year ${user['year']}',
                    user['phonenumber'],
                  ].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11.5, color: _PC.muted),
                ),
                const SizedBox(height: 8),

                // Plan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _PC.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${s['planMonths']} month${(s['planMonths'] ?? 1) == 1 ? '' : 's'} · ${months.join(', ')}',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: _PC.primaryDark),
                  ),
                ),
                const SizedBox(height: 8),

                // Bank statement check (the real proof)
                if (status == 'pending') ...[
                  _bankBox(bank, expected: expected, compact: true),
                  const SizedBox(height: 8),
                ],

                // Checks (read from the screenshot — can be edited)
                _infoRow('UTR', '${s['utr'] ?? ''}', ok: !flags.contains('DUPLICATE_UTR') && !flags.contains('UTR_NOT_IN_IMAGE'), copy: true),
                _infoRow(
                  'Amount',
                  detAmount == null
                      ? 'Not read · expected ₹$expected'
                      : '₹${detAmount.toStringAsFixed(0)} · expected ₹$expected',
                  ok: amountOk,
                ),
                _infoRow('Payee', detected['payeeMatched'] == true ? 'Ami Hostlers ✓' : 'Not matched',
                    ok: detected['payeeMatched'] == true),
                _infoRow(
                  'Paid on',
                  paidOn == null ? 'Not read' : DateFormat('d MMM yyyy').format(paidOn.toLocal()),
                  ok: paidOn != null && !flags.contains('DATE_OLD'),
                ),
                if (created != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Uploaded ${DateFormat('d MMM, h:mm a').format(created.toLocal())}',
                        style: GoogleFonts.poppins(fontSize: 10.5, color: _PC.muted)),
                  ),

                if (flags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: flags
                        .map((f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: f == 'DUPLICATE_UTR' ? _PC.redSoft : _PC.amberSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_flagText[f] ?? f,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: f == 'DUPLICATE_UTR' ? _PC.red : _PC.amber)),
                            ))
                        .toList(),
                  ),
                ],
                if ((dup['name'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Already used by ${dup['name']} (${dup['month']})',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, color: _PC.red, fontWeight: FontWeight.w600)),
                ],
                if (status == 'rejected' && (s['rejectReason'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Reason: ${s['rejectReason']}',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: _PC.red)),
                ],

                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy ? null : () => _reject(s),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _PC.red,
                            side: const BorderSide(color: Color(0xFFF5B5B5)),
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: busy ? null : () => _approve(s),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _PC.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Green / red / grey box with the bank statement result.
  Widget _bankBox(Map<String, dynamic> bank, {dynamic expected, bool compact = false}) {
    final st = (bank['status'] ?? 'not_checked').toString();
    final amt = bank['bankAmount'];
    late final Color fg;
    late final Color bg;
    late final IconData icon;
    late final String text;
    switch (st) {
      case 'verified':
        fg = _PC.green;
        bg = _PC.greenSoft;
        icon = Icons.verified_rounded;
        text = 'In bank statement · ₹$amt received${(bank['bankDay'] ?? '').toString().isNotEmpty ? ' on ${bank['bankDay']}' : ''}';
        break;
      case 'amount_low':
        fg = _PC.red;
        bg = _PC.redSoft;
        icon = Icons.money_off_rounded;
        text = 'Bank received only ₹$amt (plan ₹$expected)';
        break;
      case 'not_found':
        fg = _PC.red;
        bg = _PC.redSoft;
        icon = Icons.gpp_bad_rounded;
        text = 'NOT in bank statement — screenshot may be edited / fake';
        break;
      default:
        fg = _PC.muted;
        bg = const Color(0xFFF1F3F7);
        icon = Icons.hourglass_top_rounded;
        text = 'Not checked with bank yet — upload latest statement';
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 6 : 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {required bool ok, bool copy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded,
              size: 14, color: ok ? _PC.green : _PC.amber),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: _PC.muted)),
          ),
          Expanded(
            child: copy
                ? InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      _snack('UTR copied');
                    },
                    child: Text(value,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  )
                : Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Small red badge with the number of screenshots waiting — used on the home card.
class PendingPaymentsBadge extends StatefulWidget {
  const PendingPaymentsBadge({super.key});

  @override
  State<PendingPaymentsBadge> createState() => _PendingPaymentsBadgeState();
}

class _PendingPaymentsBadgeState extends State<PendingPaymentsBadge> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.paymentSubmissionCounts));
      final d = jsonDecode(res.body);
      if (res.statusCode == 200 && mounted) {
        setState(() => _count = (d['pending'] ?? 0) as int);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: _PC.red, borderRadius: BorderRadius.circular(10)),
      child: Text('$_count new',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}