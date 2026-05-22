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
import '../../features/backup/presentation/pages/backup_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../services/supabase/supabase_providers.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.payments,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PaymentsOverviewPage(inShell: true),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.loans,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AllLoansListPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'backup',
                    builder: (context, state) => const BackupPage(),
                  ),
                  GoRoute(
                    path: 'clients',
                    builder: (context, state) => const ClientsListPage(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const ClientFormPage(),
                      ),
                      GoRoute(
                        path: ':id',
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
                                  final clientId =
                                      state.pathParameters['id']!;
                                  return LoanCreatePage(clientId: clientId);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.dashboard,
      ),
      GoRoute(
        path: '/clients/new',
        redirect: (context, state) => AppRoutes.clientNew,
      ),
      GoRoute(
        path: '/clients/:id/loans/new',
        redirect: (context, state) =>
            AppRoutes.loanNew(state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clients/:id/loans',
        redirect: (context, state) =>
            AppRoutes.clientLoans(state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clients/:id',
        redirect: (context, state) =>
            AppRoutes.clientEdit(state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clients',
        redirect: (context, state) => AppRoutes.clients,
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
          final parcela = state.uri.queryParameters['parcela'];
          final highlightInstallment = parcela != null
              ? int.tryParse(parcela)
              : null;
          return LoanDetailPage(
            loanId: id,
            highlightInstallment: highlightInstallment,
          );
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
