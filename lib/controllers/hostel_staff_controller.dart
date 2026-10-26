import 'dart:async';

import 'package:ami_admin/apis/hostel_endpoints.dart';
import 'package:ami_admin/screens/hostel/sos_alarm_screen.dart';
import 'package:ami_admin/services/hostel_staff_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ============================================================
// HOSTEL STAFF CONTROLLER
// • live connection (Socket.io) for SOS + complaint updates
// • checks for active SOS every 20 s (backup if the socket drops)
// • plays the loud SOS alarm until someone presses "I'm going"
// ============================================================

class HostelStaffController extends GetxController with WidgetsBindingObserver {
  final HostelStaffService service = HostelStaffService();

  final RxList<Map<String, dynamic>> activeSos = <Map<String, dynamic>>[].obs;
  final RxInt unread = 0.obs;

  /// Screens listen to this and reload their lists
  final RxInt changes = 0.obs;

  final AudioPlayer _alarm = AudioPlayer();
  bool _alarmOn = false;
  final Set<String> _silenced = {};

  IO.Socket? _socket;
  Timer? _poll;
  Timer? _vibrate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _alarm.setReleaseMode(ReleaseMode.loop);
    _connect();
    refreshAll();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => refreshAll());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _vibrate?.cancel();
    _socket?.dispose();
    _alarm.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_socket == null || _socket!.disconnected) _connect();
      refreshAll();
    }
  }

  // ============================================================
  // LIVE CONNECTION
  // ============================================================

  void _connect() {
    if (!StaffSession.isLoggedIn) return;
    _socket?.dispose();

    _socket = IO.io(
      HostelEndpoints.serverRoot,
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().enableReconnection().build(),
    );
    _socket!.onConnect((_) => _socket!.emit('registerStaff', StaffSession.token));
    _socket!.onReconnect((_) {
      _socket!.emit('registerStaff', StaffSession.token);
      refreshAll();
    });

    _socket!.on('sosAlert', (_) => checkSos());
    _socket!.on('sosUpdated', (_) => checkSos());
    _socket!.on('complaintUpdated', (_) => changes.value++);
    _socket!.on('visitorAdded', (_) => changes.value++);
    _socket!.on('hostelNotification', (data) {
      unread.value++;
      changes.value++;
      if (data is Map && '${data['type']}' != 'sos') {
        Get.snackbar(
          '${data['title'] ?? 'Update'}',
          '${data['body'] ?? ''}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF171A21),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        );
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    stopAlarm();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshAll() async {
    if (!StaffSession.isLoggedIn) return;
    await Future.wait([checkSos(), loadUnread()]);
  }

  Future<void> loadUnread() async {
    final res = await service.notifications();
    if (res['success'] == true) {
      unread.value = (res['unread'] is num) ? (res['unread'] as num).toInt() : 0;
    }
  }

  // ============================================================
  // SOS
  // ============================================================

  Future<void> checkSos() async {
    if (!StaffSession.isHead) return;
    final res = await service.sosList();
    if (res['success'] != true) return;

    final list = (res['sos'] is List ? res['sos'] as List : const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    activeSos.assignAll(list);

    final ringing = list.where((s) => s['status'] == 'active' && !_silenced.contains('${s['_id']}')).toList();

    if (ringing.isEmpty) {
      stopAlarm();
      return;
    }

    startAlarm();
    if (Get.context != null && !Get.currentRoute.contains('SosAlarmScreen')) {
      Get.to(
        () => SosAlarmScreen(sosId: '${ringing.first['_id']}'),
        routeName: '/SosAlarmScreen',
      );
    }
  }

  void silence(String sosId) {
    _silenced.add(sosId);
    final stillRinging = activeSos.any((s) => s['status'] == 'active' && !_silenced.contains('${s['_id']}'));
    if (!stillRinging) stopAlarm();
  }

  Future<void> startAlarm() async {
    if (_alarmOn) return;
    _alarmOn = true;
    try {
      await _alarm.play(AssetSource('audio/sos_alarm.wav'), volume: 1.0);
    } catch (e) {
      debugPrint('Alarm sound failed: $e');
    }
    _vibrate?.cancel();
    _vibrate = Timer.periodic(const Duration(milliseconds: 900), (_) => HapticFeedback.heavyImpact());
  }

  Future<void> stopAlarm() async {
    if (!_alarmOn) return;
    _alarmOn = false;
    _vibrate?.cancel();
    try {
      await _alarm.stop();
    } catch (_) {}
  }

  /// "Test alarm" button on the dashboard
  Future<void> testAlarm() async {
    await startAlarm();
    Future.delayed(const Duration(seconds: 5), stopAlarm);
  }
}
