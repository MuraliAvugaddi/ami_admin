import 'dart:async';
import 'dart:convert';

import 'package:ami_admin/apis/hostel_endpoints.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

// ============================================================
// HOSTEL STAFF SESSION + API
// ============================================================

class StaffSession {
  static final GetStorage _box = GetStorage();

  static String? get token => _box.read('staff_token');

  static Map<String, dynamic> get staff =>
      Map<String, dynamic>.from(_box.read('staff_user') ?? const {});

  static String get role => '${staff['role'] ?? ''}';
  static String get name => '${staff['name'] ?? ''}';
  static String get trade => '${staff['trade'] ?? ''}';
  static String get id => '${staff['_id'] ?? ''}';

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static bool get isHead => ['director', 'warden', 'attender'].contains(role);

  static Future<void> save(String token, Map<String, dynamic> staff) async {
    await _box.write('staff_token', token);
    await _box.write('staff_user', staff);
  }

  static Future<void> clear() async {
    await _box.remove('staff_token');
    await _box.remove('staff_user');
  }

  static String roleName(String role) {
    switch (role) {
      case 'director':
        return 'Hostel Director';
      case 'warden':
        return 'Warden';
      case 'attender':
        return 'Attender';
      case 'worker':
        return 'Repair Team';
      case 'mess_admin':
        return 'Mess Admin';
      default:
        return role;
    }
  }

  static String tradeName(String trade) {
    switch (trade) {
      case 'electrician':
        return 'Electrician';
      case 'plumber':
        return 'Plumber';
      case 'carpenter':
        return 'Carpenter';
      case 'cleaner':
        return 'Cleaning';
      default:
        return trade;
    }
  }
}

class HostelStaffService {
  /// Called when the server says the login is no longer valid
  static void Function()? onSessionExpired;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (StaffSession.token != null) 'Authorization': 'Bearer ${StaffSession.token}',
      };

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    int seconds = 25,
  }) async {
    try {
      final response = await request().timeout(Duration(seconds: seconds));
      if (response.statusCode == 401 && StaffSession.isLoggedIn) {
        onSessionExpired?.call();
      }
      final dynamic data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        data['success'] ??= response.statusCode >= 200 && response.statusCode < 300;
        data['statusCode'] = response.statusCode;
        return data;
      }
      return {'success': false, 'message': 'Something went wrong.'};
    } on TimeoutException {
      return {'success': false, 'message': 'Server is slow. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error. Check your internet.'};
    }
  }

  Future<Map<String, dynamic>> _get(String url, [Map<String, String>? query]) {
    final uri = Uri.parse(url).replace(queryParameters: query);
    return _send(() => http.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> _post(String url, [Map<String, dynamic>? body, int seconds = 25]) {
    return _send(
      () => http.post(Uri.parse(url), headers: _headers, body: json.encode(body ?? {})),
      seconds: seconds,
    );
  }

  Future<Map<String, dynamic>> _patch(String url, Map<String, dynamic> body) {
    return _send(() => http.patch(Uri.parse(url), headers: _headers, body: json.encode(body)));
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login(String phone, String password) =>
      _post(HostelEndpoints.login, {'phone': phone, 'password': password});

  // ============================================================
  // COMPLAINTS
  // ============================================================

  /// [from] / [to] are 'yyyy-MM-dd' (calendar filter)
  Future<Map<String, dynamic>> complaints({
    String tab = 'active',
    String search = '',
    String category = '',
    String from = '',
    String to = '',
  }) =>
      _get(HostelEndpoints.complaints, {
        'tab': tab,
        if (search.isNotEmpty) 'search': search,
        if (category.isNotEmpty) 'category': category,
        if (from.isNotEmpty) 'from': from,
        if (to.isNotEmpty) 'to': to,
      });

  Future<Map<String, dynamic>> complaint(String id) => _get(HostelEndpoints.complaint(id));

  Future<Map<String, dynamic>> complaintsSummary() => _get(HostelEndpoints.complaintsSummary);

  Future<Map<String, dynamic>> complaintAction(String id, String action, [Map<String, dynamic>? body]) =>
      _post(HostelEndpoints.complaintAction(id, action), body, 60);

  // ============================================================
  // SOS
  // ============================================================

  Future<Map<String, dynamic>> sosList({bool all = false}) =>
      _get(HostelEndpoints.sos, all ? {'status': 'all'} : null);

  Future<Map<String, dynamic>> sosById(String id) => _get(HostelEndpoints.sosById(id));

  Future<Map<String, dynamic>> sosAction(String id, String action, [Map<String, dynamic>? body]) =>
      _post(HostelEndpoints.sosAction(id, action), body);

  // ============================================================
  // VISITORS
  // ============================================================

  Future<Map<String, dynamic>> visitors({String date = '', bool inside = false, String search = ''}) =>
      _get(HostelEndpoints.visitors, {
        if (date.isNotEmpty) 'date': date,
        if (inside) 'inside': 'true',
        if (search.isNotEmpty) 'search': search,
      });

  Future<Map<String, dynamic>> visitorAction(String id, String action, [Map<String, dynamic>? body]) =>
      _post(HostelEndpoints.visitorAction(id, action), body);

  // ============================================================
  // TEAM + STUDENTS
  // ============================================================

  Future<Map<String, dynamic>> team({String role = '', String trade = ''}) => _get(HostelEndpoints.team, {
        if (role.isNotEmpty) 'role': role,
        if (trade.isNotEmpty) 'trade': trade,
      });

  Future<Map<String, dynamic>> addStaff(Map<String, dynamic> body) => _post(HostelEndpoints.team, body);

  Future<Map<String, dynamic>> updateStaff(String id, Map<String, dynamic> body) =>
      _patch(HostelEndpoints.teamMember(id), body);

  Future<Map<String, dynamic>> students(String search, {String block = ''}) =>
      _get(HostelEndpoints.students, {
        if (search.isNotEmpty) 'search': search,
        if (block.isNotEmpty) 'block': block,
      });

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<Map<String, dynamic>> notifications() => _get(HostelEndpoints.notifications);

  Future<Map<String, dynamic>> markAllRead() => _post(HostelEndpoints.notificationsReadAll);
}
