import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../providers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider.notifier);
    final email = _emailController.text;
    final password = _passwordController.text;
    if (_isSignUp) {
      await auth.signUp(email, password);
    } else {
      await auth.signIn(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: Column(
                children: [
                  BrandLogo(
                    size: BrandLogoSize.medium,
                    showSubtitle: true,
                    subtitle: _isSignUp
                        ? 'Crie sua conta para começar'
                        : 'Gestão de empréstimos offline-first',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUp ? 'Cadastro' : 'Entrar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _emailController,
                            label: 'E-mail',
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o e-mail';
                              }
                              if (!v.contains('@')) return 'E-mail inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Senha',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _AuthMessageBox(
                              text: auth.error!,
                              isError: true,
                            ),
                          ],
                          if (auth.successMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _AuthMessageBox(
                              text: auth.successMessage!,
                              isError: false,
                            ),
                          ],
                          if (!_isSignUp) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: AppTextLinkButton(
                                label: 'Esqueci minha senha',
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        ref
                                            .read(authControllerProvider
                                                .notifier)
                                            .clearMessages();
                                        context.push(AppRoutes.forgotPassword);
                                      },
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          AppPrimaryButton(
                            label: _isSignUp ? 'Criar conta' : 'Entrar',
                            isLoading: auth.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextLinkButton(
                    label: _isSignUp
                        ? 'Já tenho conta — entrar'
                        : 'Não tenho conta — cadastrar',
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            ref
                                .read(authControllerProvider.notifier)
                                .clearMessages();
                            setState(() => _isSignUp = !_isSignUp);
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _AuthMessageBox extends StatelessWidget {
  const _AuthMessageBox({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? scheme.error : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
