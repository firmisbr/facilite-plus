import 'entities/client.dart';

class ClientListEntry {
  const ClientListEntry({
    required this.client,
    required this.overdueInstallments,
    required this.activeLoansCount,
  });

  final Client client;
  final int overdueInstallments;
  final int activeLoansCount;

  bool get hasDelinquency => overdueInstallments > 0;
}
