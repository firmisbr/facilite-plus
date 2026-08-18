import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/daily_loan_sunday_policy.dart';

final dailyLoanSkipSundayProvider =
    StateNotifierProvider<DailyLoanSkipSundayNotifier, bool>((ref) {
  return DailyLoanSkipSundayNotifier();
});

class DailyLoanSkipSundayNotifier extends StateNotifier<bool> {
  DailyLoanSkipSundayNotifier() : super(DailyLoanSundayPolicy.skipSunday) {
    if (!DailyLoanSundayPolicy.hydrated) {
      _load();
    } else if (state != DailyLoanSundayPolicy.skipSunday) {
      state = DailyLoanSundayPolicy.skipSunday;
    }
  }

  var _userOverride = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userOverride) return;
    final enabled = prefs.getBool(DailyLoanSundayPolicy.prefKey) ?? false;
    DailyLoanSundayPolicy.apply(enabled);
    if (!mounted) return;
    state = enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    _userOverride = true;
    DailyLoanSundayPolicy.apply(enabled);
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DailyLoanSundayPolicy.prefKey, enabled);
  }
}
