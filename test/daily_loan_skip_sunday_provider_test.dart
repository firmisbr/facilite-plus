import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facilite_plus/features/settings/domain/daily_loan_sunday_policy.dart';
import 'package:facilite_plus/features/settings/presentation/providers/daily_loan_skip_sunday_provider.dart';

void main() {
  setUp(() {
    DailyLoanSundayPolicy.apply(false);
    DailyLoanSundayPolicy.hydrated = false;
  });

  tearDown(() {
    DailyLoanSundayPolicy.apply(false);
    DailyLoanSundayPolicy.hydrated = false;
  });

  test('toggle do usuario nao e revertido pelo load atrasado das prefs', () async {
    SharedPreferences.setMockInitialValues({
      DailyLoanSundayPolicy.prefKey: false,
    });

    final notifier = DailyLoanSkipSundayNotifier();
    await notifier.setEnabled(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(notifier.state, isTrue);
    expect(DailyLoanSundayPolicy.skipSunday, isTrue);
  });
}
