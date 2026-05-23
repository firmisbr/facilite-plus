import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../reports/presentation/widgets/reports_period_tab.dart';
import '../../../reports/presentation/widgets/reports_portfolio_tab.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar_actions.dart';

enum _AdminReportsTab { period, portfolio }

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  _AdminReportsTab _tab = _AdminReportsTab.portfolio;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(adminReportsDataProvider(widget.userId));
    final userAsync = ref.watch(adminUserProvider(widget.userId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (u) => Text('Relatórios · ${u?.displayName ?? ''}'),
          loading: () => const Text('Relatórios'),
          error: (_, _) => const Text('Relatórios'),
        ),
        actions: const [AdminAppBarActions()],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          bottom: false,
          child: dataAsync.when(
            data: (data) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminReportsDataProvider(widget.userId));
                ref.invalidate(adminLoansProvider(widget.userId));
                ref.invalidate(adminPaymentsProvider(widget.userId));
                await ref.read(adminReportsDataProvider(widget.userId).future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: AppPageHeader(
                            title: 'Relatórios do usuário',
                            subtitle: 'Dados na nuvem (somente leitura).',
                            centered: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: SegmentedButton<_AdminReportsTab>(
                            segments: const [
                              ButtonSegment(
                                value: _AdminReportsTab.period,
                                label: Text('Por período'),
                              ),
                              ButtonSegment(
                                value: _AdminReportsTab.portfolio,
                                label: Text('Visão geral'),
                              ),
                            ],
                            selected: {_tab},
                            onSelectionChanged: (selected) {
                              setState(() => _tab = selected.first);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: switch (_tab) {
                          _AdminReportsTab.period => ReportsPeriodTab(
                              snapshot: data.periodReport,
                              adminUserId: widget.userId,
                            ),
                          _AdminReportsTab.portfolio => ReportsPortfolioTab(
                              overview: data.portfolio,
                            ),
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: kBottomNavReservedHeight),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: AppEmptyState(
                icon: LucideIcons.circle_alert,
                title: 'Erro ao carregar',
                subtitle: e.toString(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
