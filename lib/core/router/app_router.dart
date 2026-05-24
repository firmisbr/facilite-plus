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
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/update/presentation/pages/update_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/support/domain/support_ticket_type.dart';
import '../../features/support/presentation/pages/new_ticket_page.dart';
import '../../features/support/presentation/pages/support_home_page.dart';
import '../../features/support/presentation/pages/ticket_detail_page.dart';
import '../../features/support/presentation/pages/admin/admin_support_tickets_page.dart';
import '../../features/support/presentation/pages/admin/admin_ticket_detail_page.dart';
import '../../features/admin/domain/user_role.dart';
import '../../features/admin/presentation/pages/admin_client_loans_page.dart';
import '../../features/admin/presentation/pages/admin_clients_page.dart';
import '../../features/admin/presentation/pages/admin_loan_detail_page.dart';
import '../../features/admin/presentation/pages/admin_reports_page.dart';
import '../../features/admin/presentation/pages/admin_user_overview_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../services/supabase/supabase_providers.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isUserAppRoute(String location) {
  const userPrefixes = [
    AppRoutes.dashboard,
    AppRoutes.payments,
    AppRoutes.loans,
    AppRoutes.settings,
    AppRoutes.home,
    AppRoutes.loanCreate,
  ];
  if (userPrefixes.contains(location)) return true;
  return location.startsWith('/loans/') ||
      location.startsWith('/payments/') ||
      location.startsWith('/clients');
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(sessionProvider);
  final passwordRecovery = ref.watch(passwordRecoveryActiveProvider);
  final roleAsync = ref.watch(userRoleProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final location = state.matchedLocation;

      if (isLoading || (isLoggedIn && roleAsync.isLoading)) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final recovering = passwordRecovery.valueOrNull ?? false;
      final isAdmin = roleAsync.valueOrNull == UserRole.admin;

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
        return isAdmin ? AppRoutes.admin : AppRoutes.dashboard;
      }

      if (isAdmin) {
        if (location.startsWith('/admin')) return null;
        if (_isUserAppRoute(location) ||
            location == AppRoutes.splash ||
            location == AppRoutes.login ||
            location == AppRoutes.forgotPassword) {
          return AppRoutes.admin;
        }
        return null;
      }

      if (location.startsWith('/admin')) {
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
                    path: 'reports',
                    builder: (context, state) => const ReportsPage(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationSettingsPage(),
                  ),
                  GoRoute(
                    path: 'updates',
                    builder: (context, state) => const UpdatePage(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const SupportHomePage(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) {
                          final typeRaw =
                              state.uri.queryParameters['type'] ?? 'suporte';
                          return NewTicketPage(
                            type: SupportTicketType.fromValue(typeRaw),
                          );
                        },
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return TicketDetailPage(ticketId: id);
                        },
                      ),
                    ],
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
        path: AppRoutes.admin,
        builder: (context, state) => const AdminUsersPage(),
        routes: [
          GoRoute(
            path: 'support',
            builder: (context, state) => const AdminSupportTicketsPage(),
            routes: [
              GoRoute(
                path: ':ticketId',
                builder: (context, state) {
                  final ticketId = state.pathParameters['ticketId']!;
                  return AdminTicketDetailPage(ticketId: ticketId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'users/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return AdminUserOverviewPage(userId: userId);
            },
            routes: [
              GoRoute(
                path: 'clients',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return AdminClientsPage(userId: userId);
                },
                routes: [
                  GoRoute(
                    path: ':clientId/loans',
                    builder: (context, state) {
                      final userId = state.pathParameters['userId']!;
                      final clientId = state.pathParameters['clientId']!;
                      return AdminClientLoansPage(
                        userId: userId,
                        clientId: clientId,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'loans/:loanId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  final loanId = state.pathParameters['loanId']!;
                  return AdminLoanDetailPage(userId: userId, loanId: loanId);
                },
              ),
              GoRoute(
                path: 'reports',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return AdminReportsPage(userId: userId);
                },
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
