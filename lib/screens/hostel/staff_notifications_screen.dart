import 'package:ami_admin/screens/hostel/complaint_detail_screen.dart';
import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/screens/hostel/sos_alarm_screen.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// NOTIFICATIONS (bell) for hostel staff
// ============================================================

class StaffNotificationsScreen extends StatefulWidget {
  const StaffNotificationsScreen({super.key});

  @override
  State<StaffNotificationsScreen> createState() => _StaffNotificationsScreenState();
}

class _StaffNotificationsScreenState extends State<StaffNotificationsScreen> {
  final HostelStaffService _service = HostelStaffService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _service.notifications();
    if (!mounted) return;
    setState(() {
      _list = asMapList(res['notifications']);
      _loading = false;
    });
    if (_list.any((n) => n['isRead'] != true)) _service.markAllRead();
  }

  void _open(Map<String, dynamic> n) {
    final type = '${n['type']}';
    final id = '${n['refId'] ?? ''}';
    if (id.isEmpty) return;
    if (type.startsWith('sos') && StaffSession.isHead) {
      Get.to(() => SosAlarmScreen(sosId: id), routeName: '/SosAlarmScreen');
    } else if (type.startsWith('complaint')) {
      Get.to(() => ComplaintDetailScreen(complaintId: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: hostelAppBar('Notifications'),
      body: HostelPage(
        maxWidth: 820,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: HostelColors.chefYellow))
          : RefreshIndicator(
              color: Colors.black,
              onRefresh: _load,
              child: _list.isEmpty
                  ? ListView(children: const [HostelEmpty(icon: Icons.notifications_off_rounded, title: 'No notifications yet')])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                      itemCount: _list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = _list[i];
                        final unread = n['isRead'] != true;
                        final isSos = '${n['type']}'.startsWith('sos');
                        return HostelCard(
                          padding: const EdgeInsets.all(14),
                          color: unread ? const Color(0xFFFFF8DC) : Colors.white,
                          onTap: () => _open(n),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (isSos ? HostelColors.sosRed : HostelColors.orange).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isSos ? Icons.sos_rounded : Icons.handyman_rounded,
                                  color: isSos ? HostelColors.sosRed : HostelColors.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${n['title'] ?? ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                        color: HostelColors.textPrimary,
                                      ),
                                    ),
                                    if ('${n['body'] ?? ''}'.isNotEmpty)
                                      Text(
                                        '${n['body']}',
                                        style: GoogleFonts.poppins(fontSize: 12, height: 1.4, color: HostelColors.textSecondary),
                                      ),
                                    const SizedBox(height: 3),
                                    Text(agoText(n['createdAt']),
                                        style: GoogleFonts.poppins(fontSize: 10.5, color: HostelColors.textSecondary)),
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
