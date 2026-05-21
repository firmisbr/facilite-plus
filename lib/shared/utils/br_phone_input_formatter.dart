import 'package:flutter/services.dart';

/// Celular BR: `(XX) 9 XXXX-XXXX` (11 dígitos: DDD + 9 + número).
class BrPhoneInputFormatter extends TextInputFormatter {
  const BrPhoneInputFormatter();

  static const _maxDigits = 11;

  static String? digitsOnly(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var d = value.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return null;

    if (d.startsWith('55') && d.length > 11) {
      d = d.substring(d.length - 11);
    }
    return d;
  }

  static String formatFromDigits(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';

    final len = d.length > _maxDigits ? _maxDigits : d.length;
    final buf = StringBuffer('(');

    if (len >= 1) {
      buf.write(d.substring(0, len >= 2 ? 2 : 1));
    }
    if (len >= 2) {
      buf.write(') ');
      buf.write(d[2]);
    }
    if (len >= 4) {
      buf.write(' ');
      buf.write(d.substring(3, len >= 7 ? 7 : len));
    }
    if (len >= 8) {
      buf.write('-');
      buf.write(d.substring(7, len));
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
