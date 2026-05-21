import 'package:flutter/services.dart';

/// Entrada em centavos: cada dígito desloca à esquerda (ex.: `300000` → `3.000,00`).
class BrCurrencyInputFormatter extends TextInputFormatter {
  const BrCurrencyInputFormatter();

  static String formatFromDigits(String digitsOnly) {
    if (digitsOnly.isEmpty) return '';
    final cents = int.tryParse(digitsOnly);
    if (cents == null) return '';
    return _formatValue(cents / 100);
  }

  static String _formatValue(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final dec = parts[1];
    final withThousands = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$withThousands,$dec';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = formatFromDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
