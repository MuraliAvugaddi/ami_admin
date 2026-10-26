import 'package:ami_admin/apis/apis_localhost.dart';

// ============================================================
// HOSTEL STAFF ENDPOINTS (complaints, SOS, visitors, team)
// ============================================================

class HostelEndpoints {
  static const String staffBase = '${ApiEndpoints.baseUrl}/staff';

  /// Server root for Socket.io ("https://xxx.onrender.com")
  static String get serverRoot => ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  static const String login = '$staffBase/login';
  static const String me = '$staffBase/me';

  static const String notifications = '$staffBase/notifications';
  static const String notificationsReadAll = '$staffBase/notifications/read-all';

  static const String team = '$staffBase/team';
  static String teamMember(String id) => '$staffBase/team/$id';
  static const String students = '$staffBase/students';

  static const String complaints = '$staffBase/complaints';
  static const String complaintsSummary = '$staffBase/complaints-summary';
  static String complaint(String id) => '$staffBase/complaints/$id';
  static String complaintAction(String id, String action) => '$staffBase/complaints/$id/$action';

  static const String sos = '$staffBase/sos';
  static String sosById(String id) => '$staffBase/sos/$id';
  static String sosAction(String id, String action) => '$staffBase/sos/$id/$action';

  static const String visitors = '$staffBase/visitors';
  static String visitorAction(String id, String action) => '$staffBase/visitors/$id/$action';

  /// Visitor gate QR poster (open in browser and print)
  static String get gateQrPage => '$serverRoot/gate-qr';
}
