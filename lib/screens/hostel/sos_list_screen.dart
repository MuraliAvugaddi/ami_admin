import 'package:ami_admin/controllers/hostel_staff_controller.dart';
import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/screens/hostel/sos_alarm_screen.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// SOS HISTORY — all emergency alerts
// ============================================================

class SosListScreen extends StatefulWidget {
  const SosListScreen({super.key});

  @override
  State<SosListScreen> createState() => _SosListScreenState();
}

class _SosListScreenState extends State<SosListScreen> {
  final HostelStaffService _service = HostelStaffService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  Worker? _live;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<HostelStaffController>()) {
      _live = ever(Get.find<HostelStaffController>().activeSos, (_) => _load(silent: true));
    }
    _load();
  }

  @override
  void dispose() {
    _live?.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _service.sosList(all: true);
    if (!mounted) return;
    setState(() {
      _list = asMapList(res['sos']);
      _loading = false;
    });
  }

  Color _color(String status) {
    switch (status) {
      case 'active':
        return HostelColors.sosRed;
      case 'on_the_way':
        return HostelColors.orange;
      default:
        return HostelColors.green;
    }
  }

  String _statusText(Map<String, dynamic> s) {
    switch ('${s['status']}') {
      case 'active':
        return 'Waiting for help';
      case 'on_the_way':
        return '${s['goingName'] ?? 'Staff'} on the way';
      default:
        final by = '${s['handledName'] ?? ''}'.trim();
        return by.isEmpty ? 'Handled' : 'Handled by $by';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: hostelAppBar('SOS Alerts', subtitle: 'Last 200 emergencies'),
      body: HostelPage(
        maxWidth: 1100,
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
                    HostelEmpty(icon: Icons.verified_user_rounded, title: 'No SOS yet', subtitle: 'All safe in the hostel.'),
                  ])
                : HostelResponsiveList(
                    itemCount: _list.length,
                    maxColumns: 2,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                    itemBuilder: (_, i) {
                      final s = _list[i];
                      final color = _color('${s['status']}');
                      return HostelCard(
                        padding: const EdgeInsets.all(14),
                        border: s['status'] == 'active' ? HostelColors.sosRed : null,
                        onTap: () async {
                          await Get.to(() => SosAlarmScreen(sosId: '${s['_id']}'), routeName: '/SosAlarmScreen');
                          _load(silent: true);
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.sos_rounded, color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${HostelLabels.sos('${s['type']}')} — ${s['studentName']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: HostelColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Block ${s['hostelblock']} • Room ${s['room']} • ${dateTimeText(s['createdAt'])}',
                                    style: GoogleFonts.poppins(fontSize: 11, color: HostelColors.textSecondary),
                                  ),
                                  const SizedBox(height: 5),
                                  HostelChip(_statusText(s), color: color),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      ),
    );
  }
}
