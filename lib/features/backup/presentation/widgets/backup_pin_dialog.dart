import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/backup_snapshot.dart';
import '../../domain/backup_transfer_pin.dart';

/// Solicita PIN de 4 dígitos (criação com confirmação ou só verificação).
Future<String?> showBackupTransferPinDialog(
  BuildContext context, {
  required BackupPinDialogMode mode,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _BackupPinDialog(mode: mode),
  );
}

enum BackupPinDialogMode {
  createForExport,
  verifyForImport,
}

class _BackupPinDialog extends StatefulWidget {
  const _BackupPinDialog({required this.mode});

  final BackupPinDialogMode mode;

  @override
  State<_BackupPinDialog> createState() => _BackupPinDialogState();
}

class _BackupPinDialogState extends State<_BackupPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isCreate => widget.mode == BackupPinDialogMode.createForExport;

  void _submit() {
    final pin = _pinController.text;
    try {
      BackupTransferPin.validateFormat(pin);
      if (_isCreate) {
        if (pin != _confirmController.text) {
          setState(() => _error = 'Os PINs não coincidem.');
          return;
        }
      }
      Navigator.pop(context, pin);
    } on BackupException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCreate
        ? 'PIN de transferência'
        : 'Informe o PIN do backup';
    final subtitle = _isCreate
        ? 'Defina 4 dígitos para permitir importar este backup '
            'em outra conta. Guarde o PIN com segurança.'
        : 'Digite o PIN definido ao exportar o backup na conta original.';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_isCreate) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Confirmar PIN',
                  counterText: '',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isCreate ? 'Continuar' : 'Confirmar'),
        ),
      ],
    );
  }
}
