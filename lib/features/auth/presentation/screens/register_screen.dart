import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_call_assistant/features/auth/presentation/auth_provider.dart';
import 'package:smart_call_assistant/core/constants/app_constants.dart';
import 'package:smart_call_assistant/l10n/app_localizations.dart';
import 'package:smart_call_assistant/core/components/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed / فشل التسجيل'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 10),
            const Text('Verify Email / تفعيل الحساب'),
          ],
        ),
        content: const Text(
            'We have sent a verification link to your email. Please check your Inbox & Spam folders.\n\nلقد أرسلنا رابط تفعيل لبريدك الإلكتروني. يرجى مراجعة البريد الوارد والرسائل المزعجة.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppConstants.routeLogin);
            },
            child: const Text('OK / حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.register),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeInDown(child: const AppLogo(size: 70, showText: false)),
                  const SizedBox(height: 24),

                  FadeInLeft(
                    child: Text(
                      'Create Account / حساب جديد',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Input
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: l10n.fullName,
                        prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Input
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: Icon(Icons.lock_outlined, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v != null && v.length < 6) ? 'At least 6 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        prefixIcon: Icon(Icons.lock_reset_outlined, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (v) => v != _passwordController.text ? 'Passwords match required' : null,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 1000),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                          child: authProvider.isLoading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text(l10n.register.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  FadeIn(
                    delay: const Duration(milliseconds: 1200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.alreadyHaveAccount),
                        TextButton(
                          onPressed: () => context.go(AppConstants.routeLogin),
                          child: Text(l10n.login, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
