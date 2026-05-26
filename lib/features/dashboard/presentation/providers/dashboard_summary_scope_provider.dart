import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/dashboard_summary_scope.dart';

const _prefKey = 'dashboard_summary_scope';

final dashboardSummaryScopeProvider =
    StateNotifierProvider<DashboardSummaryScopeNotifier, DashboardSummaryScope>(
  (ref) => DashboardSummaryScopeNotifier(),
);

class DashboardSummaryScopeNotifier extends StateNotifier<DashboardSummaryScope> {
  DashboardSummaryScopeNotifier() : super(DashboardSummaryScope.total) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored == 'currentMonth') {
      state = DashboardSummaryScope.currentMonth;
    }
  }

  Future<void> setScope(DashboardSummaryScope scope) async {
    state = scope;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      scope == DashboardSummaryScope.currentMonth ? 'currentMonth' : 'total',
    );
  }
}
