import 'package:drift/drift.dart';
import 'loans_table.dart';

class PaymentsTable extends Table {
  @override
  String get tableName => 'payments';

  TextColumn get id => text()();
  TextColumn get loanId => text().named('loan_id').references(LoansTable, #id)();
  TextColumn get amount => text()();
  TextColumn get paymentDate => text().named('payment_date').nullable()();
  TextColumn get method => text().nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
}
