import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../firebase_options.dart';
import '../../providers/auth_provider.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // Set after successful creation to show credential card
  Map<String, String>? _created;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final orgId = context.read<AuthProvider>().currentUser!.orgId;
    FirebaseApp? secondaryApp;

    try {
      // Use unique name to avoid conflicts on repeated creation
      secondaryApp = await Firebase.initializeApp(
        name: 'emp_create_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'role': 'employee',
        'orgId': orgId,
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();

      if (mounted) {
        setState(() {
          _created = {
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'password': _passwordCtrl.text,
          };
          _loading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'Email already has an account.',
          'invalid-email' => 'Invalid email address.',
          'weak-password' => 'Password too weak (min 6 characters).',
          _ => e.message ?? 'Failed to create account.',
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Try again.';
        _loading = false;
      });
    } finally {
      await secondaryApp?.delete();
    }
  }

  void _reset() {
    setState(() {
      _created = null;
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Employee Account'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _created != null
              ? _CredentialCard(creds: _created!, onCreateAnother: _reset)
              : _CreateForm(
                  formKey: _formKey,
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  loading: _loading,
                  error: _error,
                  onSubmit: _create,
                ),
        ),
      ),
    );
  }
}

// ── Create form ───────────────────────────────────────────────────────────────

class _CreateForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _CreateForm({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Creates a login for the employee. Share the email and password with them — they can log in immediately.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _FormCard(children: [
            _Field(
              controller: nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Enter employee name' : null,
            ),
            const Divider(height: 1),
            _Field(
              controller: emailCtrl,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.trim().isEmpty) return 'Enter email';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const Divider(height: 1),
            _Field(
              controller: passwordCtrl,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: obscure,
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              validator: (v) =>
                  v!.length < 6 ? 'Min 6 characters' : null,
            ),
          ]),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.priorityHighSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_outlined, size: 18),
              label: Text(loading ? 'Creating…' : 'Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Credential card shown after success ───────────────────────────────────────

class _CredentialCard extends StatelessWidget {
  final Map<String, String> creds;
  final VoidCallback onCreateAnother;

  const _CredentialCard({required this.creds, required this.onCreateAnother});

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = creds['name']!;
    final email = creds['email']!;
    final password = creds['password']!;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Column(
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusDoneSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.statusDone.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusDone.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.statusDone, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Created!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusDone,
                      ),
                    ),
                    const Text(
                      'Share these credentials with the employee.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Credential card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Employee',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Email row
              _CredRow(
                label: 'Email',
                value: email,
                icon: Icons.email_outlined,
                onCopy: () => _copy(context, email, 'Email'),
              ),
              const Divider(height: 1),
              // Password row
              _CredRow(
                label: 'Password',
                value: password,
                icon: Icons.lock_outline,
                onCopy: () => _copy(context, password, 'Password'),
              ),
              const Divider(height: 1),
              // App URL row
              _CredRow(
                label: 'App URL',
                value: 'employee-tracker-ed5a6.web.app',
                icon: Icons.open_in_browser_outlined,
                onCopy: () => _copy(
                    context, 'https://employee-tracker-ed5a6.web.app', 'URL'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Copy all button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copy(
              context,
              'Name: $name\nEmail: $email\nPassword: $password\nApp: https://employee-tracker-ed5a6.web.app',
              'All credentials',
            ),
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: const Text('Copy All Credentials'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCreateAnother,
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Create Another Account'),
          ),
        ),
      ],
    );
  }
}

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onCopy;

  const _CredRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.copy_outlined,
                  size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared form components ────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        hintText: label,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        suffixIcon: suffixIcon,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        fillColor: Colors.transparent,
      ),
      validator: validator,
    );
  }
}
