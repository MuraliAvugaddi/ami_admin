import 'package:ami_admin/screens/hostel/hostel_widgets.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// STAFF ACCOUNTS (director only)
// Add warden / attender / repair team / mess admin,
// disable, reset password
// ============================================================

class StaffAccountsScreen extends StatefulWidget {
  const StaffAccountsScreen({super.key});

  @override
  State<StaffAccountsScreen> createState() => _StaffAccountsScreenState();
}

class _StaffAccountsScreenState extends State<StaffAccountsScreen> {
  static const List<String> _roles = ['warden', 'attender', 'worker', 'mess_admin', 'director'];
  static const List<String> _trades = ['electrician', 'plumber', 'carpenter', 'cleaner'];

  final HostelStaffService _service = HostelStaffService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _service.team();
    if (!mounted) return;
    setState(() {
      _list = asMapList(res['staff']);
      _loading = false;
    });
  }

  // ============================================================
  // ADD STAFF
  // ============================================================

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    String role = 'worker';
    String trade = 'electrician';

    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          isDense: true,
          labelStyle: GoogleFonts.poppins(fontSize: 12.5),
          prefixIcon: Icon(icon, size: 19),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    final body = await Get.dialog<Map<String, dynamic>>(
      StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add staff', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: deco('Full name', Icons.person_outline_rounded)),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: deco('Mobile number (login ID)', Icons.phone_android_rounded).copyWith(counterText: ''),
                ),
                const SizedBox(height: 10),
                TextField(controller: password, decoration: deco('Password (min 6)', Icons.lock_outline_rounded)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: deco('Role', Icons.badge_outlined),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(StaffSession.roleName(r), style: GoogleFonts.poppins(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setLocal(() => role = v ?? role),
                ),
                if (role == 'worker') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: trade,
                    decoration: deco('Work', Icons.handyman_outlined),
                    items: _trades
                        .map((t) => DropdownMenuItem(value: t, child: Text(StaffSession.tradeName(t), style: GoogleFonts.poppins(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setLocal(() => trade = v ?? trade),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HostelColors.chefYellow,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              onPressed: () => Get.back(result: {
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'password': password.text.trim(),
                'role': role,
                if (role == 'worker') 'trade': trade,
              }),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (body == null) return;
    final res = await _service.addStaff(body);
    showResult(res);
    if (res['success'] == true) _load();
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _toggle(Map<String, dynamic> s) async {
    final res = await _service.updateStaff('${s['_id']}', {'isActive': s['isActive'] == false});
    showResult(res);
    _load();
  }

  Future<void> _resetPassword(Map<String, dynamic> s) async {
    final pass = await askText('New password for ${s['name']}', hint: 'Min 6 characters', ok: 'Change', lines: 1);
    if (pass == null || pass.isEmpty) return;
    final res = await _service.updateStaff('${s['_id']}', {'password': pass});
    showResult(res, okText: 'Password changed');
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final s in _list) {
      groups.putIfAbsent('${s['role']}', () => []).add(s);
    }
    const order = ['director', 'warden', 'attender', 'worker', 'mess_admin'];

    return Scaffold(
      backgroundColor: HostelColors.background,
      appBar: hostelAppBar('Staff Accounts', subtitle: '${_list.length} people'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: HostelColors.chefYellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('Add staff', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: HostelPage(
        maxWidth: 900,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: HostelColors.chefYellow))
          : RefreshIndicator(
              color: Colors.black,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                children: [
                  for (final role in order)
                    if (groups[role] != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                        child: Text(
                          StaffSession.roleName(role).toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: HostelColors.textSecondary,
                          ),
                        ),
                      ),
                      for (final s in groups[role]!) ...[_staffTile(s), const SizedBox(height: 8)],
                    ],
                ],
              ),
            ),
      ),
    );
  }

  Widget _staffTile(Map<String, dynamic> s) {
    final active = s['isActive'] != false;
    final isMe = '${s['_id']}' == StaffSession.id;
    final trade = '${s['trade'] ?? ''}';
    return HostelCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      color: active ? Colors.white : const Color(0xFFF1F2F4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: active ? HostelColors.chefYellow.withValues(alpha: 0.25) : HostelColors.borderColor,
            child: Icon(
              s['role'] == 'worker' ? Icons.engineering_rounded : Icons.person_rounded,
              size: 19,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s['name']}${isMe ? ' (you)' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: active ? HostelColors.textPrimary : HostelColors.textSecondary,
                  ),
                ),
                Text(
                  '${s['phone']}${trade.isEmpty ? '' : ' • ${StaffSession.tradeName(trade)}'}${active ? '' : ' • Disabled'}',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: HostelColors.textSecondary),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'call') callNumber('${s['phone']}');
              if (v == 'password') _resetPassword(s);
              if (v == 'toggle') _toggle(s);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'call', child: Text('Call')),
              const PopupMenuItem(value: 'password', child: Text('Reset password')),
              if (!isMe) PopupMenuItem(value: 'toggle', child: Text(active ? 'Disable login' : 'Enable login')),
            ],
          ),
        ],
      ),
    );
  }
}
