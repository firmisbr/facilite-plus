import 'package:flutter/services.dart';

/// CPF brasileiro: `000.000.000-00` (11 dígitos).
class BrCpfInputFormatter extends TextInputFormatter {
  const BrCpfInputFormatter();

  static const _maxDigits = 11;

  static String? digitsOnly(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final d = value.replaceAll(RegExp(r'\D'), '');
    return d.isEmpty ? null : d;
  }

  static String formatFromDigits(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';

    final buf = StringBuffer();
    for (var i = 0; i < d.length && i < _maxDigits; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  static String formatDisplay(String? raw) {
    final digits = digitsOnly(raw);
    if (digits == null) return '';
    return formatFromDigits(digits);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxDigits) return oldValue;

    final formatted = formatFromDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
