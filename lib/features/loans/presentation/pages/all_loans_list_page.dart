import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/loan_list_filter.dart';
import '../providers/loans_providers.dart';
import '../widgets/loan_list_card.dart';

class AllLoansListPage extends ConsumerStatefulWidget {
  const AllLoansListPage({super.key});

  @override
  ConsumerState<AllLoansListPage> createState() => _AllLoansListPageState();
}

class _AllLoansListPageState extends ConsumerState<AllLoansListPage> {
  LoanListFilter _filter = LoanListFilter.ativos;

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(allLoansProvider);
    final paymentsAsync = ref.watch(allPaymentsForUserProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          bottom: false,
          child: loansAsync.when(
            data: (allLoans) {
              return paymentsAsync.when(
                data: (payments) {
                  final loans = LoanListFilterHelper.apply(
                    items: allLoans,
                    payments: payments,
                    filter: _filter,
                  );

                  return RefreshIndicator(
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
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.md,
                                  AppSpacing.lg,
                                  AppSpacing.sm,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Empréstimos',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      loans.isEmpty
                                          ? _emptySubtitle(_filter)
                                          : '${loans.length} registro(s) · ${_filterLabel(_filter)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context
                                                .appTheme.textSecondary,
                                          ),
                                    ),
                                  ],
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Column(
                                  children: [
                                    const _LoansSectionLabel(
                                      title: 'Filtrar',
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          AppFilterChip(
                                            label: 'Ativos',
                                            selected: _filter ==
                                                LoanListFilter.ativos,
                                            onSelected: () => setState(
                                              () => _filter =
                                                  LoanListFilter.ativos,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.sm,
                                          ),
                                          AppFilterChip(
                                            label: 'Atrasados',
                                            selected: _filter ==
                                                LoanListFilter.atrasados,
                                            onSelected: () => setState(
                                              () => _filter =
                                                  LoanListFilter.atrasados,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.sm,
                                          ),
                                          AppFilterChip(
                                            label: 'Quitados',
                                            selected: _filter ==
                                                LoanListFilter.quitados,
                                            onSelected: () => setState(
                                              () => _filter =
                                                  LoanListFilter.quitados,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.sm,
                                          ),
                                          AppFilterChip(
                                            label: 'Todos',
                                            selected: _filter ==
                                                LoanListFilter.todos,
                                            onSelected: () => setState(
                                              () => _filter =
                                                  LoanListFilter.todos,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.lg),
                        ),
                        if (loans.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.lg),
                                  child: AppEmptyState(
                                    icon: LucideIcons.wallet,
                                    title: _emptyTitle(_filter),
                                    subtitle: _emptySubtitle(_filter),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              kBottomNavReservedHeight + AppSpacing.lg,
                            ),
                            sliver: SliverList.separated(
                              itemCount: loans.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                return Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: AppSpacing.maxContentWidth,
                                    ),
                                    child: LoanListCard(item: loans[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: AppEmptyState(
                    icon: LucideIcons.circle_alert,
                    title: 'Erro ao carregar pagamentos',
                    subtitle: e.toString(),
                  ),
                ),
              );
            },
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

  static String _filterLabel(LoanListFilter filter) => switch (filter) {
        LoanListFilter.ativos => 'ativos',
        LoanListFilter.atrasados => 'com atraso',
        LoanListFilter.quitados => 'quitados',
        LoanListFilter.todos => 'todos',
      };

  static String _emptyTitle(LoanListFilter filter) => switch (filter) {
        LoanListFilter.ativos => 'Nenhum empréstimo ativo',
        LoanListFilter.atrasados => 'Nenhum empréstimo em atraso',
        LoanListFilter.quitados => 'Nenhum empréstimo quitado',
        LoanListFilter.todos => 'Nenhum empréstimo',
      };

  static String _emptySubtitle(LoanListFilter filter) => switch (filter) {
        LoanListFilter.ativos =>
          'Use o botão + na barra inferior para criar um empréstimo.',
        LoanListFilter.atrasados =>
          'Ótimo! Nenhuma parcela pendente está vencida.',
        LoanListFilter.quitados =>
          'Empréstimos totalmente pagos aparecem aqui.',
        LoanListFilter.todos => 'Cadastre seu primeiro empréstimo.',
      };
}

class _LoansSectionLabel extends StatelessWidget {
  const _LoansSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.appTheme.border;
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        );

    return Row(
      children: [
        Expanded(child: _DashedLine(color: lineColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(title, style: titleStyle),
        ),
        Expanded(child: _DashedLine(color: lineColor)),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 20,
          width: constraints.maxWidth,
          child: Center(
            child: CustomPaint(
              size: Size(constraints.maxWidth, 1),
              painter: _DashedLinePainter(color: color),
            ),
          ),
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    var x = 0.0;
    final y = size.height / 2;

    while (x < size.width) {
      final end = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
