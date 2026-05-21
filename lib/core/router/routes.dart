abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';

  /// Shell — menu lateral
  static const clients = '/clients';
  static const dashboard = '/dashboard';

  /// Legado: redireciona para [clients]
  static const home = '/home';

  /// Telas em stack (sem drawer)
  static const clientNew = '/clients/new';
  static String clientEdit(String id) => '/clients/$id';
  static String clientLoans(String clientId) => '/clients/$clientId/loans';
  static String loanNew(String clientId) => '/clients/$clientId/loans/new';
  static String loanEdit(String id) => '/loans/$id';
  static String loanPayments(String loanId) => '/loans/$loanId/payments';
  static String paymentNew(String loanId) => '/loans/$loanId/payments/new';
  static String paymentEdit(String id) => '/payments/$id';
}
