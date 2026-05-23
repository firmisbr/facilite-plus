abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/login/forgot-password';
  static const resetPassword = '/login/reset-password';

  /// Shell — barra inferior
  static const dashboard = '/dashboard';
  static const payments = '/payments';
  static const loans = '/loans';
  static const settings = '/settings';

  /// Clientes (dentro do shell — aba Configurações)
  static const backup = '/settings/backup';
  static const reports = '/settings/reports';
  static const notifications = '/settings/notifications';
  static const updates = '/settings/updates';
  static const clients = '/settings/clients';
  static const clientNew = '/settings/clients/new';
  static String clientEdit(String id) => '/settings/clients/$id';
  static String clientLoans(String clientId) => '/settings/clients/$clientId/loans';
  static String loanNew(String clientId) =>
      '/settings/clients/$clientId/loans/new';

  /// Legado: redireciona para [dashboard]
  static const home = '/home';

  /// Telas em stack (fora do shell — sem barra inferior)
  static const loanCreate = '/loans/new';
  static String loanDetail(String id, {int? highlightInstallment}) {
    if (highlightInstallment == null) return '/loans/$id';
    return '/loans/$id?parcela=$highlightInstallment';
  }
  static String loanEdit(String id) => '/loans/$id/edit';
  static String loanPayments(String loanId) => '/loans/$loanId/payments';
  static String paymentNew(String loanId) => '/loans/$loanId/payments/new';
  static String paymentEdit(String id) => '/payments/$id';

  /// Painel administrativo (somente role admin)
  static const admin = '/admin';
  static String adminUserOverview(String userId) => '/admin/users/$userId';
  static String adminUserClients(String userId) => '/admin/users/$userId/clients';
  static String adminClientLoans(String userId, String clientId) =>
      '/admin/users/$userId/clients/$clientId/loans';
  static String adminLoanDetail(String userId, String loanId) =>
      '/admin/users/$userId/loans/$loanId';
  static String adminUserReports(String userId) => '/admin/users/$userId/reports';
}
