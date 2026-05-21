import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Campo em card com rótulo discreto no topo (sem efeitos de brilho).
class FloatingLabelInputCard extends StatelessWidget {
  const FloatingLabelInputCard({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.textAlign = TextAlign.start,
    this.prefixText,
    this.suffixText,
    this.hintText,
    this.fieldStyle,
    this.required = false,
    this.obscureText = false,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final TextAlign textAlign;
  final String? prefixText;
  final String? suffixText;
  final String? hintText;
  final TextStyle? fieldStyle;
  final bool required;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedStyle = fieldStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.3,
        );
    final border = context.appTheme.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.accent.withValues(alpha: 0.85),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            autocorrect: autocorrect,
            textAlign: textAlign,
            obscureText: obscureText,
            readOnly: readOnly,
            onTap: onTap,
            style: resolvedStyle,
            decoration: InputDecoration(
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixText: prefixText,
              prefixStyle: resolvedStyle,
              suffixText: suffixText,
              suffixStyle: resolvedStyle,
              hintText: hintText,
              hintStyle: resolvedStyle?.copyWith(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: maxLines > 1 ? AppSpacing.sm : AppSpacing.md,
                horizontal: 0,
              ),
              isDense: false,
            ),
          ),
        ],
      ),
    );
  }
}
