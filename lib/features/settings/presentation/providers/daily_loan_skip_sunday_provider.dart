import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/daily_loan_sunday_policy.dart';

const _prefKey = 'daily_loan_skip_sunday';

final dailyLoanSkipSundayProvider =
    StateNotifierProvider<DailyLoanSkipSundayNotifier, bool>((ref) {
  return DailyLoanSkipSundayNotifier();
});

class DailyLoanSkipSundayNotifier extends StateNotifier<bool> {
  DailyLoanSkipSundayNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefKey) ?? false;
    DailyLoanSundayPolicy.skipSunday = enabled;
    state = enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    DailyLoanSundayPolicy.skipSunday = enabled;
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }
}
