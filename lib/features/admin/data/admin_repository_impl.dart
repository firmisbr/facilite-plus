import 'package:supabase_flutter/supabase_flutter.dart';

import '../../clients/domain/entities/client.dart';
import '../../loans/domain/entities/loan.dart';
import '../../loans/domain/entities/loan_with_client.dart';
import '../../payments/domain/entities/payment.dart';
import '../domain/admin_user.dart';
import '../domain/repositories/admin_repository.dart';
import '../domain/user_role.dart';
import 'admin_row_mapper.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Future<UserRole> fetchCurrentUserRole() async {
    final userId = _userId;
    if (userId == null) return UserRole.guest;

    final row = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return AdminRowMapper.roleFromRow(
      row == null ? null : Map<String, dynamic>.from(row),
    );
  }

  @override
  Future<List<AdminUser>> fetchAppUsers() async {
    final rows = await _supabase
        .from('profiles')
        .select('id, name, email, created_at, role')
        .eq('role', 'user')
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final name = row['name'] as String?;
      final email = row['email'] as String? ?? '';
      return AdminUser(
        id: row['id'] as String,
        name: name?.trim().isNotEmpty == true ? name!.trim() : email,
        email: email,
        createdAt: row['created_at']?.toString(),
      );
    }).toList();
  }

  @override
  Future<AdminUser?> fetchUserById(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select('id, name, email, created_at')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    final map = Map<String, dynamic>.from(row);
    final email = map['email'] as String? ?? '';
    final name = map['name'] as String?;
    return AdminUser(
      id: map['id'] as String,
      name: name?.trim().isNotEmpty == true ? name!.trim() : email,
      email: email,
      createdAt: map['created_at']?.toString(),
    );
  }

  @override
  Future<List<Client>> fetchClientsForUser(String userId) async {
    final rows = await _supabase
        .from('clients')
        .select()
        .eq('user_id', userId)
        .order('name');

    return (rows as List<dynamic>)
        .map((raw) => AdminRowMapper.clientFromRow(
              Map<String, dynamic>.from(raw as Map),
            ))
        .toList();
  }

  @override
  Future<List<LoanWithClient>> fetchLoansForUser(String userId) async {
    final clients = await fetchClientsForUser(userId);
    if (clients.isEmpty) return [];

    final clientIds = clients.map((c) => c.id).toList();
    final namesById = {for (final c in clients) c.id: c.name};

    final rows = await _supabase
        .from('loans')
        .select()
        .inFilter('client_id', clientIds)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map((raw) {
      final loan = AdminRowMapper.loanFromRow(
        Map<String, dynamic>.from(raw as Map),
      );
      return LoanWithClient(
        loan: loan,
        clientName: namesById[loan.clientId] ?? 'Cliente',
      );
    }).toList();
  }

  @override
  Future<List<Payment>> fetchPaymentsForUser(String userId) async {
    final loans = await fetchLoansForUser(userId);
    if (loans.isEmpty) return [];

    final loanIds = loans.map((l) => l.loan.id).toList();
    final rows = await _supabase
        .from('payments')
        .select()
        .inFilter('loan_id', loanIds)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((raw) => AdminRowMapper.paymentFromRow(
              Map<String, dynamic>.from(raw as Map),
            ))
        .toList();
  }

  @override
  Future<Loan?> fetchLoanById(String loanId) async {
    final row = await _supabase
        .from('loans')
        .select()
        .eq('id', loanId)
        .maybeSingle();

    if (row == null) return null;
    return AdminRowMapper.loanFromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Client?> fetchClientById(String clientId) async {
    final row = await _supabase
        .from('clients')
        .select()
        .eq('id', clientId)
        .maybeSingle();

    if (row == null) return null;
    return AdminRowMapper.clientFromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<Payment>> fetchPaymentsForLoan(String loanId) async {
    final rows = await _supabase
        .from('payments')
        .select()
        .eq('loan_id', loanId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((raw) => AdminRowMapper.paymentFromRow(
              Map<String, dynamic>.from(raw as Map),
            ))
        .toList();
  }
}
