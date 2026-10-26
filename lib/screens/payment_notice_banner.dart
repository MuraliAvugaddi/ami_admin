import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../apis/apis_localhost.dart';

// =====================================================================
// MODEL
// =====================================================================
class PaymentNotice {
  final bool enabled;
  final String name;
  final DateTime? dueDate;
  final String? amount;
  final String? contact;
  final String dbName;
  final String dbLink;
  final String serverName;
  final String serverLink;

  PaymentNotice({
    required this.enabled,
    required this.name,
    this.dueDate,
    this.amount,
    this.contact,
    required this.dbName,
    required this.dbLink,
    required this.serverName,
    required this.serverLink,
  });

  factory PaymentNotice.fromJson(Map<String, dynamic> j) => PaymentNotice(
    enabled: j['enabled'] == true || j['enabled'].toString() == 'true',
    name: (j['name'] ?? 'Admin').toString(),
    dueDate: j['dueDate'] != null
        ? DateTime.tryParse(j['dueDate'].toString().trim())
        : null,
    amount: j['amount']?.toString(),
    contact: j['contact']?.toString(),
    dbName: (j['dbName'] ?? 'MongoDB Atlas Database').toString(),
    dbLink: (j['dbLink'] ?? 'https://cloud.mongodb.com').toString(),
    serverName: (j['serverName'] ?? 'Server Hosting').toString(),
    serverLink: (j['serverLink'] ?? 'https://dashboard.render.com').toString(),
  );

  bool get isActive => enabled && dueDate != null;

  int get daysLeft {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  bool get isOverdue => daysLeft < 0;
  bool get isUrgent => daysLeft <= 3;

  String get dueText =>
      dueDate == null ? '' : DateFormat('d MMMM yyyy').format(dueDate!);

  bool get hasAmount => amount != null && amount!.trim().isNotEmpty;
  bool get hasContact => contact != null && contact!.trim().isNotEmpty;

  String get headline {
    if (isOverdue) return 'Your service plan has expired';
    if (daysLeft == 0) return 'Your service plan expires today';
    if (daysLeft == 1) return 'Your service plan expires tomorrow';
    return 'Your service plan expires in $daysLeft days';
  }

  String get body {
    final amt = hasAmount
        ? 'the pending amount of ₹$amount'
        : 'the pending amount';

    if (isOverdue) {
      return 'Dear $name, your plan for Ami Hostlers hosting services '
          '(server & database) expired on $dueText. Please clear $amt to '
          'resume uninterrupted access to the admin panel and student app. '
          'Services will remain paused until payment is received.';
    }

    return 'Dear $name, your current plan for Ami Hostlers hosting '
        'services (server & database) is valid till $dueText.\n\n'
        'Please clear $amt before the due date to continue uninterrupted '
        'access to the admin panel and student app. Once the validity ends, '
        'services will be paused until payment is received.';
  }

  Color get accent =>
      isUrgent ? const Color(0xFFC62828) : const Color(0xFFB26A00);

  Color get tint =>
      isUrgent ? const Color(0xFFFDECEA) : const Color(0xFFFFF4E0);
}

// =====================================================================
// SHARED SERVICE (one API call for the whole app + shared dialog)
// =====================================================================
class PaymentNoticeService {
  static PaymentNotice? _cached;
  static Future<PaymentNotice?>? _pending;
  static bool _dialogOpen = false;

  /// Fetches the notice once and reuses it on every screen.
  static Future<PaymentNotice?> load() {
    if (_cached != null) return Future.value(_cached);
    _pending ??= _fetch();
    return _pending!;
  }

  static Future<PaymentNotice?> _fetch() async {
    try {
      final res = await http
          .get(Uri.parse(ApiEndpoints.systemNotice))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        debugPrint('🔔 Notice: status ${res.statusCode}');
        _pending = null;
        return null;
      }
      _cached = PaymentNotice.fromJson(json.decode(res.body));
      return _cached;
    } catch (e) {
      debugPrint('🔔 Notice: request failed → $e');
      _pending = null;
      return null;
    }
  }

  /// Shows the notice dialog. Completes when "OK, got it" is pressed.
  static Future<void> showNoticeDialog(
    BuildContext context,
    PaymentNotice n,
  ) async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final accent = n.accent;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: accent, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    n.headline,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.body,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        height: 1.55,
                        color: const Color(0xFF2B2F38),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Valid till', n.dueText),
                    if (n.hasAmount) _infoRow('Amount due', '₹${n.amount}'),
                    if (n.hasContact) _infoRow('Contact', n.contact!),
                    const SizedBox(height: 14),
                    Text(
                      'Services included in this plan',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF171A21),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _linkTile(
                      icon: Icons.storage_rounded,
                      title: n.dbName,
                      link: n.dbLink,
                    ),
                    const SizedBox(height: 8),
                    _linkTile(
                      icon: Icons.dns_rounded,
                      title: n.serverName,
                      link: n.serverLink,
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'OK, got it',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  static Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Widget _linkTile({
    required IconData icon,
    required String title,
    required String link,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openLink(link),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E6EC)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF546E7A)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF171A21),
                    ),
                  ),
                  Text(
                    link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF3949AB),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: Color(0xFF3949AB),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF737B8C),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF171A21),
            ),
          ),
        ),
      ],
    ),
  );
}

// =====================================================================
// BANNER (top of screen) — auto popup only once per day
// =====================================================================
class PaymentNoticeBanner extends StatefulWidget {
  const PaymentNoticeBanner({super.key});

  @override
  State<PaymentNoticeBanner> createState() => _PaymentNoticeBannerState();
}

class _PaymentNoticeBannerState extends State<PaymentNoticeBanner> {
  static const String _storageKey = 'chef_notice_popup_last_shown';
  static bool _dialogHandledThisRun = false;

  PaymentNotice? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool _popupAlreadyShownToday() {
    try {
      return html.window.localStorage[_storageKey] == _todayKey;
    } catch (_) {
      return false;
    }
  }

  void _markPopupShownToday() {
    try {
      html.window.localStorage[_storageKey] = _todayKey;
    } catch (_) {}
  }

  Future<void> _load() async {
    final n = await PaymentNoticeService.load();
    if (n == null || !n.isActive || !mounted) return;

    setState(() => _notice = n);

    // Screens with a PaymentNoticeGate show the dialog on first tap instead.
    final hasGate =
        context.findAncestorStateOfType<_PaymentNoticeGateState>() != null;

    if (!hasGate && !_dialogHandledThisRun && !_popupAlreadyShownToday()) {
      _dialogHandledThisRun = true;
      _markPopupShownToday();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) PaymentNoticeService.showNoticeDialog(context, n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _notice;
    if (n == null) return const SizedBox.shrink();

    final accent = n.accent;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: n.tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: accent, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.headline,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 13.5 : 15,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n.body,
                  maxLines: isMobile ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 11.5 : 12.5,
                    height: 1.45,
                    color: const Color(0xFF2B2F38),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => PaymentNoticeService.showNoticeDialog(context, n),
            style: TextButton.styleFrom(foregroundColor: accent),
            child: Text(
              'Details',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// GATE — wrap a screen with this. Every time the screen is opened,
// the FIRST tap anywhere shows the notice. After "OK, got it",
// the screen works normally.
// =====================================================================
class PaymentNoticeGate extends StatefulWidget {
  final Widget child;
  const PaymentNoticeGate({super.key, required this.child});

  @override
  State<PaymentNoticeGate> createState() => _PaymentNoticeGateState();
}

class _PaymentNoticeGateState extends State<PaymentNoticeGate> {
  PaymentNotice? _notice;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await PaymentNoticeService.load();
    if (n == null || !n.isActive || !mounted) return;
    setState(() {
      _notice = n;
      _locked = true;
    });
  }

  Future<void> _onBlockedTap() async {
    final n = _notice;
    if (n == null) return;
    await PaymentNoticeService.showNoticeDialog(context, n);
    if (mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _onBlockedTap(),
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}