import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

/// Calendário Material em português com tema do app.
abstract final class AppDatePicker {
  static const locale = Locale('pt', 'BR');

  static String formatLong(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(date);
  }

  static String formatMedium(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  static Future<DateTime?> open(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String helpText = 'Selecionar data',
  }) {
    final theme = Theme.of(context);

    return showDatePicker(
      context: context,
      locale: locale,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      fieldLabelText: 'Data',
      fieldHintText: 'dd/mm/aaaa',
      errorFormatText: 'Data inválida',
      errorInvalidText: 'Fora do intervalo',
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.accent,
              onPrimary: const Color(0xFFF4F1EA),
            ),
            datePickerTheme: theme.datePickerTheme.copyWith(
              backgroundColor: theme.colorScheme.surface,
              headerBackgroundColor: AppColors.accent,
              headerForegroundColor: const Color(0xFFF4F1EA),
              headerHeadlineStyle: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFFF4F1EA),
                fontWeight: FontWeight.w600,
              ),
              headerHelpStyle: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFFF4F1EA).withValues(alpha: 0.85),
              ),
              weekdayStyle: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              dayStyle: theme.textTheme.bodyLarge,
              yearStyle: theme.textTheme.bodyLarge,
              todayForegroundColor: WidgetStateProperty.all(AppColors.accent),
              todayBorder: const BorderSide(color: AppColors.accent, width: 1.5),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFF4F1EA);
                }
                if (states.contains(WidgetState.disabled)) {
                  return theme.colorScheme.onSurface.withValues(alpha: 0.35);
                }
                return theme.colorScheme.onSurface;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.accent;
                }
                return null;
              }),
              rangeSelectionBackgroundColor:
                  AppColors.accent.withValues(alpha: 0.18),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
