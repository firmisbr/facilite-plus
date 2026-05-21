abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const clientNew = '/clients/new';
  static String clientEdit(String id) => '/clients/$id';
}
