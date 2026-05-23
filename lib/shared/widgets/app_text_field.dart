import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'floating_label_input_card.dart';

/// Campo de formulário padrão do app (card com rótulo no topo).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.suffixIcon,
    this.autocorrect = true,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.required,
    this.textAlign = TextAlign.start,
    this.prefixText,
    this.suffixText,
    this.textCapitalization = TextCapitalization.none,
    this.fieldStyle,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool? required;
  final TextAlign textAlign;
  final String? prefixText;
  final String? suffixText;
  final TextCapitalization textCapitalization;
  final TextStyle? fieldStyle;

  static String displayLabel(String? label) {
    if (label == null) return 'Campo';
    return label
        .replaceAll('*', '')
        .replaceAll(RegExp(r'\s*\(opcional\)\s*', caseSensitive: false), '')
        .trim();
  }

  static bool isRequiredLabel(String? label, bool? required) {
    if (required != null) return required;
    return label != null && label.contains('*');
  }

  static IconData iconForLabel(String? label) {
    final l = (label ?? '').toLowerCase();
    if (l.contains('e-mail') || l.contains('email')) return LucideIcons.mail;
    if (l.contains('senha') || l.contains('password')) {
      return LucideIcons.lock;
    }
    if (l.contains('whatsapp') ||
        l.contains('telefone') ||
        l.contains('phone')) {
      return LucideIcons.phone;
    }
    if (l.contains('cpf') || l.contains('documento')) {
      return LucideIcons.id_card;
    }
    if (l.contains('nome')) return LucideIcons.user_round;
    if (l.contains('endereço') || l.contains('endereco')) {
      return LucideIcons.map_pin;
    }
    if (l.contains('valor')) return LucideIcons.banknote;
    if (l.contains('parcela')) return LucideIcons.layers;
    if (l.contains('juros')) return LucideIcons.percent;
    if (l.contains('data') || l.contains('vencimento')) {
      return LucideIcons.calendar;
    }
    if (l.contains('observ')) return LucideIcons.notepad_text;
    if (l.contains('confirmar')) return LucideIcons.lock_keyhole;
    return LucideIcons.pencil;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingLabelInputCard(
      icon: icon ?? iconForLabel(label),
      label: displayLabel(label),
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      textAlign: textAlign,
      prefixText: prefixText,
      suffixText: suffixText,
      hintText: hint,
      fieldStyle: fieldStyle,
      required: isRequiredLabel(label, required),
      obscureText: obscureText,
      suffixIcon: suffixIcon,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}
