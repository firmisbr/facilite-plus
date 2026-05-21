abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/login/forgot-password';
  static const resetPassword = '/login/reset-password';

  /// Shell — menu lateral
  static const clients = '/clients';
  static const loans = '/loans';
  static const payments = '/payments';
  static const dashboard = '/dashboard';

  /// Legado: redireciona para [dashboard]
  static const home = '/home';

  /// Telas em stack (sem drawer)
  static const clientNew = '/clients/new';
  static String clientEdit(String id) => '/clients/$id';
  static String clientLoans(String clientId) => '/clients/$clientId/loans';
  static const loanCreate = '/loans/new';
  static String loanNew(String clientId) => '/clients/$clientId/loans/new';
  static String loanDetail(String id) => '/loans/$id';
  static String loanEdit(String id) => '/loans/$id/edit';
  static String loanPayments(String loanId) => '/loans/$loanId/payments';
  static String paymentNew(String loanId) => '/loans/$loanId/payments/new';
  static String paymentEdit(String id) => '/payments/$id';
}
