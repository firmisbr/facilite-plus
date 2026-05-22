import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../domain/reports_data.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../providers/reports_providers.dart';
import '../reports_share.dart';
import '../widgets/reports_period_tab.dart';
import '../widgets/reports_portfolio_tab.dart';

enum _ReportsTab { period, portfolio }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _exporting = false;
  _ReportsTab _tab = _ReportsTab.period;

  Future<void> _exportCsv() async {
    final data = ref.read(reportsDataProvider).valueOrNull;
    if (data == null) return;

    setState(() => _exporting = true);
    try {
      await shareReportsCsv(data);
    } on ReportsShareException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  bool _canExport(ReportsData? data) {
    if (data == null || !data.hasActiveLoans) return false;
    if (_tab == _ReportsTab.period) {
      return data.periodReport.hasPeriodData;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(reportsDataProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: const SizedBox.shrink(),
        toolbarHeight: kToolbarHeight,
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
                ref.invalidate(allLoansProvider);
                ref.invalidate(allPaymentsForUserProvider);
                await Future<void>.delayed(
                  const Duration(milliseconds: 400),
                );
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
                        child: const AppPageHeader(
                          title: 'Relatórios',
                          subtitle:
                              'Análise por período ou visão completa da carteira.',
                          centered: true,
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
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: SegmentedButton<_ReportsTab>(
                            segments: const [
                              ButtonSegment(
                                value: _ReportsTab.period,
                                label: Text('Por período'),
                              ),
                              ButtonSegment(
                                value: _ReportsTab.portfolio,
                                label: Text('Visão geral'),
                              ),
                            ],
                            selected: {_tab},
                            onSelectionChanged: (selected) {
                              setState(() => _tab = selected.first);
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
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
                          _ReportsTab.period => ReportsPeriodTab(
                              snapshot: data.periodReport,
                            ),
                          _ReportsTab.portfolio => ReportsPortfolioTab(
                              overview: data.portfolio,
                            ),
                        },
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
                            AppSpacing.lg,
                            AppSpacing.lg,
                            kBottomNavReservedHeight + AppSpacing.md,
                          ),
                          child: FilledButton.icon(
                            onPressed: _canExport(data) && !_exporting
                                ? _exportCsv
                                : null,
                            icon: _exporting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(LucideIcons.share_2),
                            label: Text(
                              _exporting
                                  ? 'Preparando…'
                                  : 'Exportar relatório (CSV)',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppEmptyState(
                  icon: LucideIcons.circle_alert,
                  title: 'Erro ao carregar',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
