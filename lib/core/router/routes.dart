abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const clientNew = '/clients/new';
  static String clientEdit(String id) => '/clients/$id';
  static String clientLoans(String clientId) => '/clients/$clientId/loans';
  static String loanNew(String clientId) => '/clients/$clientId/loans/new';
  static String loanEdit(String id) => '/loans/$id';
}
