class ApiEndpoints {
  // ✅ CHANGE ONLY THIS ONE LINE — the whole admin app uses it
  //   Phone (same Wi-Fi as Mac) : 'http://192.168.1.33:5002'
  //   Mac / Chrome              : 'http://localhost:5002'
  //   Render (after deploy)     : 'https://YOUR-RENDER-NAME.onrender.com'
  static const String serverUrl = 'https://ami-backend-v1.onrender.com';

  static const String baseUrl = '$serverUrl/api';
  static const String socketUrl = serverUrl; // Sockets connect to the host root

  static const String adminBase = '$baseUrl/admin';

  static const String adminUsers = '$adminBase/users';
  static const String adminHistory = '$adminBase/history';
  static const String adminAllPayments = '$adminBase/all-payments';
  static const String adminSkipReport = '$adminBase/skip-report';
  static const String adminDayScholarOrders = '$adminBase/dayscholar-orders';

  static const String adminManualPayment = '$adminBase/payments/manual';
  static const String adminDeleteMonthPayment = '$adminBase/payments/month';
  static const String adminExportExcel = '$adminBase/reports/export-excel';

  static const String menuActive = '$baseUrl/menu/active';
  static const String adminUploadMenu = '$baseUrl/admin/menu/upload';
  static const String adminAddItem = '$adminBase/add-item';
  static const String adminDeleteItem = '$adminBase/delete-item';

  static const String specialFoodBase = '$baseUrl/special-food';
  static const String specialFoodMenu = '$specialFoodBase/menu';

  static const String adminFeedbackList = '$baseUrl/admin/feedback';
  static const String tokenStats = '$baseUrl/tokens/stats';

  // ✅ Payment / server notice shown on admin home screen
  static const String systemNotice = '$baseUrl/system/notice';

  // ✅ System status (home screen banner)
  static const String systemStatus = '$baseUrl/system/status';

  // ✅ UPI screenshot payments
  static const String paymentSubmissions = '$adminBase/payment-submissions';
  static const String paymentSubmissionCounts =
      '$adminBase/payment-submissions/counts';
  static String approveSubmission(String id) =>
      '$adminBase/payment-submissions/$id/approve';
  static String rejectSubmission(String id) =>
      '$adminBase/payment-submissions/$id/reject';
  static String studentReceipts(String userId) =>
      '$adminBase/students/$userId/receipts';

  static const String submissions = '$adminBase/payment-submissions';
  static const String submissionCounts =
      '$adminBase/payment-submissions/counts';
  static String approve(String id) =>
      '$adminBase/payment-submissions/$id/approve';
  static String reject(String id) =>
      '$adminBase/payment-submissions/$id/reject';

  static const String adminAuthToken = 'YOUR_ADMIN_JWT_TOKEN';
}