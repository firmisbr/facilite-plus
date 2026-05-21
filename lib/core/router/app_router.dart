import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_shell.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/providers/password_recovery_provider.dart';
import '../../features/clients/presentation/pages/client_form_page.dart';
import '../../features/clients/presentation/pages/clients_list_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/loans/presentation/pages/all_loans_list_page.dart';
import '../../features/loans/presentation/pages/loan_create_page.dart';
import '../../features/loans/presentation/pages/loan_detail_page.dart';
import '../../features/loans/presentation/pages/loan_form_page.dart';
import '../../features/loans/presentation/pages/loans_list_page.dart';
import '../../features/payments/presentation/pages/payment_form_page.dart';
import '../../features/payments/presentation/pages/payments_list_page.dart';
import '../../features/payments/presentation/pages/payments_overview_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../services/supabase/supabase_providers.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(sessionProvider);
  final passwordRecovery = ref.watch(passwordRecoveryActiveProvider);

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

      final recovering = passwordRecovery.valueOrNull ?? false;

      if (!isLoggedIn) {
        const authPaths = {
          AppRoutes.login,
          AppRoutes.forgotPassword,
          AppRoutes.resetPassword,
        };
        return authPaths.contains(location) ? null : AppRoutes.login;
      }

      if (recovering && location != AppRoutes.resetPassword) {
        return AppRoutes.resetPassword;
      }

      if (!recovering && location == AppRoutes.resetPassword) {
        return AppRoutes.dashboard;
      }

      if (location == AppRoutes.splash ||
          location == AppRoutes.login ||
          location == AppRoutes.forgotPassword) {
        return AppRoutes.dashboard;
      }

      if (location == AppRoutes.home) {
        return AppRoutes.dashboard;
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
        routes: [
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordPage(),
          ),
          GoRoute(
            path: 'reset-password',
            builder: (context, state) => const ResetPasswordPage(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.clients,
            builder: (context, state) => const ClientsListPage(),
          ),
          GoRoute(
            path: AppRoutes.loans,
            builder: (context, state) => const AllLoansListPage(),
          ),
          GoRoute(
            path: AppRoutes.payments,
            builder: (context, state) => const PaymentsOverviewPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.dashboard,
      ),
      GoRoute(
        path: AppRoutes.clientNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClientFormPage(),
      ),
      GoRoute(
        path: '/clients/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClientFormPage(clientId: id);
        },
        routes: [
          GoRoute(
            path: 'loans',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final clientId = state.pathParameters['id']!;
              return LoansListPage(clientId: clientId);
            },
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final clientId = state.pathParameters['id']!;
                  return LoanCreatePage(clientId: clientId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.loanCreate,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoanCreatePage(),
      ),
      GoRoute(
        path: '/loans/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LoanDetailPage(loanId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LoanFormPage(loanId: id);
            },
          ),
          GoRoute(
            path: 'payments',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final loanId = state.pathParameters['id']!;
              return PaymentsListPage(loanId: loanId);
            },
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final loanId = state.pathParameters['id']!;
                  return PaymentFormPage(loanId: loanId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/payments/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PaymentFormPage(paymentId: id);
        },
      ),
    ],
  );
});
