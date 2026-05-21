import 'loan.dart';

class LoanWithClient {
  const LoanWithClient({
    required this.loan,
    required this.clientName,
  });

  final Loan loan;
  final String clientName;
}
