import '../../../clients/domain/entities/client.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/domain/entities/loan_with_client.dart';
import '../../../payments/domain/entities/payment.dart';
import '../admin_user.dart';
import '../user_role.dart';

abstract class AdminRepository {
  Future<UserRole> fetchCurrentUserRole();

  Future<List<AdminUser>> fetchAppUsers();

  Future<AdminUser?> fetchUserById(String userId);

  Future<List<Client>> fetchClientsForUser(String userId);

  Future<List<LoanWithClient>> fetchLoansForUser(String userId);

  Future<List<Payment>> fetchPaymentsForUser(String userId);

  Future<Loan?> fetchLoanById(String loanId);

  Future<Client?> fetchClientById(String clientId);

  Future<List<Payment>> fetchPaymentsForLoan(String loanId);
}
