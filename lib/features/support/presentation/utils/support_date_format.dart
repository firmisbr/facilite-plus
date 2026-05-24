import 'package:intl/intl.dart';

String formatSupportDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(local);
}
