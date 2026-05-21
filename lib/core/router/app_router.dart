import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/clients/presentation/pages/client_form_page.dart';
import '../../features/clients/presentation/pages/clients_list_page.dart';
import '../../features/loans/presentation/pages/loan_form_page.dart';
import '../../features/loans/presentation/pages/loans_list_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../services/supabase/supabase_providers.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(sessionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final location = state.matchedLocation;

      if (isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (!isLoggedIn) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      if (location == AppRoutes.splash || location == AppRoutes.login) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const ClientsListPage(),
      ),
      GoRoute(
        path: AppRoutes.clientNew,
        builder: (context, state) => const ClientFormPage(),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClientFormPage(clientId: id);
        },
        routes: [
          GoRoute(
            path: 'loans',
            builder: (context, state) {
              final clientId = state.pathParameters['id']!;
              return LoansListPage(clientId: clientId);
            },
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final clientId = state.pathParameters['id']!;
                  return LoanFormPage(clientId: clientId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/loans/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LoanFormPage(loanId: id);
        },
      ),
    ],
  );
});
