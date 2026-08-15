import 'package:supabase_flutter/supabase_flutter.dart';

import '../../admin/data/admin_row_mapper.dart';
import '../../admin/domain/admin_user.dart';
import '../../clients/domain/entities/client.dart';
import '../../loans/domain/entities/loan.dart';
import '../../payments/domain/entities/payment.dart';

/// Leitura na nuvem liberada pelo PIN de suporte (RPCs security definer).
class SupportImportRepository {
  SupportImportRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<AdminUser>> fetchProfiles(String pin) async {
    final rows = await _supabase.rpc<List<dynamic>>(
      'support_list_profiles',
      params: {'p_pin': pin},
    );

    return rows.map((raw) {
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

  Future<List<Client>> fetchClients({
    required String pin,
    required String userId,
  }) async {
    final rows = await _supabase.rpc<List<dynamic>>(
      'support_fetch_clients',
      params: {'p_pin': pin, 'p_user_id': userId},
    );

    return rows
        .map(
          (raw) => AdminRowMapper.clientFromRow(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
  }

  Future<List<Loan>> fetchLoans({
    required String pin,
    required String userId,
  }) async {
    final rows = await _supabase.rpc<List<dynamic>>(
      'support_fetch_loans',
      params: {'p_pin': pin, 'p_user_id': userId},
    );

    return rows
        .map(
          (raw) => AdminRowMapper.loanFromRow(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
  }

  Future<List<Payment>> fetchPayments({
    required String pin,
    required String userId,
  }) async {
    final rows = await _supabase.rpc<List<dynamic>>(
      'support_fetch_payments',
      params: {'p_pin': pin, 'p_user_id': userId},
    );

    return rows
        .map(
          (raw) => AdminRowMapper.paymentFromRow(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
  }
}
