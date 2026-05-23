import 'package:drift/drift.dart';
import 'loans_table.dart';

class PaymentsTable extends Table {
  @override
  String get tableName => 'payments';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get loanId => text().named('loan_id').references(LoansTable, #id)();
  TextColumn get amount => text()();
  IntColumn get installmentNumber =>
      integer().named('installment_number').nullable()();
  TextColumn get paymentDate => text().named('payment_date').nullable()();
  TextColumn get method => text().nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
}
