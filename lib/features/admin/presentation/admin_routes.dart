import '../../../../core/router/routes.dart';

abstract final class AdminRoutes {
  static const home = AppRoutes.admin;
  static String userOverview(String userId) => AppRoutes.adminUserOverview(userId);
  static String userClients(String userId) => AppRoutes.adminUserClients(userId);
  static String clientLoans(String userId, String clientId) =>
      AppRoutes.adminClientLoans(userId, clientId);
  static String loanDetail(String userId, String loanId) =>
      AppRoutes.adminLoanDetail(userId, loanId);
  static String userReports(String userId) => AppRoutes.adminUserReports(userId);
  static const support = AppRoutes.adminSupport;
  static String supportTicket(String id) => AppRoutes.adminSupportTicket(id);
}
