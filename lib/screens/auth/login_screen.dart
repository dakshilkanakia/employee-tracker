import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      final user = auth.currentUser!;
      context.go(user.isManager ? '/manager' : '/employee');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 720) {
            return _WideLayout(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              passCtrl: _passCtrl,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
            );
          }
          return _NarrowLayout(
            formKey: _formKey,
            emailCtrl: _emailCtrl,
            passCtrl: _passCtrl,
            obscure: _obscure,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onSubmit: _submit,
          );
        },
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _WideLayout({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Brand panel
        Container(
          width: 420,
          color: AppColors.sidebarBg,
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BrandMark(),
                  SizedBox(height: 40),
                  Text(
                    'Manage your team\'s tasks, track progress, and stay on top of deadlines — all in one place.',
                    style: TextStyle(
                      color: AppColors.sidebarText,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 40),
                  _FeatureRow(
                    Icons.assignment_turned_in_outlined,
                    'Task tracking with photo proof',
                  ),
                  SizedBox(height: 16),
                  _FeatureRow(
                    Icons.notifications_outlined,
                    'Real-time push notifications',
                  ),
                  SizedBox(height: 16),
                  _FeatureRow(
                    Icons.bar_chart_outlined,
                    'Employee performance insights',
                  ),
                ],
              ),
            ),
          ),
        ),
        // Form panel
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _LoginForm(
                  formKey: formKey,
                  emailCtrl: emailCtrl,
                  passCtrl: passCtrl,
                  obscure: obscure,
                  onToggleObscure: onToggleObscure,
                  onSubmit: onSubmit,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _NarrowLayout({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const _BrandMark(dark: false),
            const SizedBox(height: 40),
            _LoginForm(
              formKey: formKey,
              emailCtrl: emailCtrl,
              passCtrl: passCtrl,
              obscure: obscure,
              onToggleObscure: onToggleObscure,
              onSubmit: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final bool dark;
  const _BrandMark({this.dark = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.task_alt, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          'TaskFlow',
          style: TextStyle(
            color: dark ? Colors.white : AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 18),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.sidebarText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to your account',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                v!.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) => v!.length >= 6 ? null : 'Too short',
            onFieldSubmitted: (_) => onSubmit(),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                auth.error!,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: auth.loading ? null : onSubmit,
            child: auth.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Sign In'),
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Don't have an account?",
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/signup/manager'),
            icon: const Icon(Icons.business_outlined, size: 18),
            label: const Text('Create Manager Account'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/signup/employee'),
            icon: const Icon(Icons.vpn_key_outlined, size: 18),
            label: const Text('Join with Invite Code'),
          ),
        ],
      ),
    );
  }
}
