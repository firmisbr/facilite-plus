import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoanListCardLayout { extended, compact }

const _prefKey = 'loans_list_card_layout';

final loanListLayoutProvider =
    StateNotifierProvider<LoanListLayoutNotifier, LoanListCardLayout>((ref) {
  return LoanListLayoutNotifier();
});

class LoanListLayoutNotifier extends StateNotifier<LoanListCardLayout> {
  LoanListLayoutNotifier() : super(LoanListCardLayout.extended) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored == 'compact') state = LoanListCardLayout.compact;
  }

  Future<void> setLayout(LoanListCardLayout layout) async {
    state = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      layout == LoanListCardLayout.compact ? 'compact' : 'extended',
    );
  }

  Future<void> toggle() async {
    await setLayout(
      state == LoanListCardLayout.extended
          ? LoanListCardLayout.compact
          : LoanListCardLayout.extended,
    );
  }
}
