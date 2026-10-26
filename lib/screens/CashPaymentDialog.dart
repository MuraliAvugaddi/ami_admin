// =====================================================================
// CASH PAYMENT — Student Finance → 💵 button on a student.
// Admin picks Monthly / 3 Months / 6 Months, enters the cash received,
// and the student instantly gets a notification + receipt with PAID stamp.
// =====================================================================
import 'dart:convert';

import 'package:ami_admin/apis/apis_localhost.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../apis/api_endpoints.dart';

/// URLs built from your existing ApiEndpoints — nothing to add there.
class CashApi {
  static String _base(String userId) =>
      ApiEndpoints.studentReceipts(userId).replaceFirst(RegExp(r'/receipts$'), '');
  static String feeStatus(String userId) => '${_base(userId)}/fee-status';
  static String cashPayment(String userId) => '${_base(userId)}/cash-payment';
}

class _K {
  static const primary = Color(0xFFFFC800);
  static const primaryDark = Color(0xFF9A7600);
  static const primarySoft = Color(0xFFFFF6CC);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE5EAF2);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFEAF8EF);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFFEEEE);
  static const blue = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFEFF4FF);
}

String _money(num v) => NumberFormat.decimalPattern('en_IN').format(v.round());

/// Returns true when a cash payment was saved (refresh your list).
Future<bool> showCashPaymentDialog(BuildContext context,
    {required String userId, required String name}) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CashPaymentDialog(userId: userId, name: name),
  );
  return r == true;
}

class _CashPaymentDialog extends StatefulWidget {
  final String userId;
  final String name;
  const _CashPaymentDialog({required this.userId, required this.name});

  @override
  State<_CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<_CashPaymentDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _data = {};
  int _planIndex = 0;
  bool _waiveFine = false;
  bool _amountEdited = false;

  List<Map<String, dynamic>> get _plans =>
      List<Map<String, dynamic>>.from((_data['plans'] ?? const []).map((e) => Map<String, dynamic>.from(e)));
  Map<String, dynamic> get _plan => _plans.isEmpty ? {} : _plans[_planIndex];
  int get _planAmount => ((_plan['amount'] ?? 0) as num).toInt();
  int get _fine => _waiveFine ? 0 : ((_data['fine'] ?? 0) as num).toInt();
  int get _suggested => _planAmount + _fine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(CashApi.feeStatus(widget.userId)));
      final d = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200 && d['success'] == true) {
        setState(() {
          _data = Map<String, dynamic>.from(d);
          _loading = false;
          _amount.text = '$_suggested';
        });
      } else {
        setState(() {
          _loading = false;
          _error = d['message']?.toString() ?? 'Could not load student fee status.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection error. Check the server.';
      });
    }
  }

  void _refreshAmount() {
    if (!_amountEdited) _amount.text = '$_suggested';
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Enter the cash amount received.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse(CashApi.cashPayment(widget.userId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'planMonths': _plan['months'],
          'amount': amount,
          'waiveFine': _waiveFine,
          'note': _note.text.trim(),
        }),
      );
      final d = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200 && d['success'] == true) {
        final receipt = Map<String, dynamic>.from(d['receipt'] ?? {});
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.of(context).pop(true);
        messenger?.showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _K.green,
          duration: const Duration(seconds: 5),
          content: Text(
            '✅ Cash saved · Receipt ${receipt['receiptNo'] ?? ''} sent to ${widget.name}',
            style: GoogleFonts.poppins(),
          ),
        ));
      } else {
        setState(() {
          _saving = false;
          _error = d['message']?.toString() ?? 'Could not save.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Connection error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _loading
            ? const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: _K.primary)))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: _K.greenSoft, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.payments_rounded, color: _K.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cash payment',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17)),
                              Text(widget.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(fontSize: 12.5, color: _K.muted)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    if (_data.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _statusBox(),
                      const SizedBox(height: 16),
                      Text('Plan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...List.generate(_plans.length, _planOption),
                      if (((_data['fine'] ?? 0) as num) > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _waiveFine ? const Color(0xFFF3F4F6) : _K.redSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Late fine ₹${_money((_data['fine'] ?? 0) as num)}'
                                  '${_waiveFine ? ' (waived)' : ''}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: _waiveFine ? _K.muted : _K.red),
                                ),
                              ),
                              Text('Waive', style: GoogleFonts.poppins(fontSize: 12, color: _K.muted)),
                              Switch(
                                value: _waiveFine,
                                activeColor: _K.green,
                                onChanged: (v) => setState(() {
                                  _waiveFine = v;
                                  _refreshAmount();
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: _K.greenSoft, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: _K.green),
                                const SizedBox(width: 6),
                                Text('Mode: Cash',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700, fontSize: 12.5, color: _K.green)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text('Suggested ₹${_money(_suggested)}',
                              style: GoogleFonts.poppins(fontSize: 11.5, color: _K.muted)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() => _amountEdited = true),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Cash received (₹)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _note,
                        maxLength: 120,
                        decoration: InputDecoration(
                          labelText: 'Note (optional) — e.g. received by Ramesh',
                          labelStyle: GoogleFonts.poppins(fontSize: 12.5),
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _K.redSoft, borderRadius: BorderRadius.circular(10)),
                        child: Text(_error!,
                            style: GoogleFonts.poppins(fontSize: 12.5, color: _K.red, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_data.isNotEmpty)
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.verified_rounded),
                          label: Text(
                            'Save & send receipt · ₹${_money(int.tryParse(_amount.text) ?? 0)}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _K.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'The student gets a notification and a receipt with the Ami Hostlers PAID stamp.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 11, color: _K.muted),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statusBox() {
    final state = (_data['state'] ?? '').toString();
    final pending = List<String>.from(_data['pendingMonths'] ?? const []);
    String text;
    Color fg;
    Color bg;
    switch (state) {
      case 'active':
      case 'expiring':
        final till = DateTime.tryParse('${_data['accessExpiresAt'] ?? ''}');
        text = 'Paid till ${till == null ? '-' : DateFormat('d MMM yyyy').format(till.toLocal())}. '
            'This cash payment will be for the next months.';
        fg = _K.green;
        bg = _K.greenSoft;
        break;
      case 'pending':
        text = 'A UPI screenshot for ${pending.join(', ')} is waiting in Payment Requests. '
            'Reject it first if the student is paying cash for the same month.';
        fg = _K.blue;
        bg = _K.blueSoft;
        break;
      case 'late':
        text = '${_data['currentMonth']} is unpaid — late fine ₹${_money((_data['fine'] ?? 0) as num)}.';
        fg = _K.red;
        bg = _K.redSoft;
        break;
      default:
        text = '${_data['currentMonth']} is unpaid.';
        fg = _K.primaryDark;
        bg = _K.primarySoft;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: fg, fontWeight: FontWeight.w600, height: 1.4)),
    );
  }

  Widget _planOption(int i) {
    final p = _plans[i];
    final months = ((p['months'] ?? 1) as num).toInt();
    final labels = List<String>.from(p['monthLabels'] ?? const []);
    final selected = i == _planIndex;
    final title = months == 1
        ? 'Monthly'
        : months == 6
            ? 'Half Semester (6 months)'
            : '$months Months';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _planIndex = i;
          _refreshAmount();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _K.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _K.primaryDark : _K.border, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? _K.primaryDark : _K.muted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(labels.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 11, color: _K.muted)),
                  ],
                ),
              ),
              Text('₹${_money((p['amount'] ?? 0) as num)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}