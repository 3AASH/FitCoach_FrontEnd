import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../auth/forgot_password_screen.dart';
import '../../../core/theme/app_palette.dart';

/// Change the account password.
///
/// Accounts created through phone OTP have no password at all. There is nothing
/// for them to confirm against, so this screen sends them to the OTP reset flow
/// instead of showing a form that can only fail.
class ChangePasswordScreen extends StatefulWidget {
  final UserRepository? userRepository;

  const ChangePasswordScreen({super.key, this.userRepository});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  String? _error;

  UserRepository get _userRepository =>
      widget.userRepository ?? UserRepository();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final languageProvider = context.read<LanguageProvider>();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await _userRepository.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(languageProvider.t('change_password_success'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = languageProvider.t('change_password_error');
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final t = languageProvider.t;
    final hasPassword = authProvider.user?.hasPassword ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(t('change_password_title'))),
      body: hasPassword
          ? _buildForm(t)
          : _buildNoPasswordNotice(t),
    );
  }

  Widget _buildNoPasswordNotice(String Function(String, {Map<String, String>? args}) t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(t('change_password_none_title'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                t('change_password_none_body'),
                style: TextStyle(color: context.palette.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(t('change_password_set_with_otp')),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(String Function(String, {Map<String, String>? args}) t) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            child: Column(
              children: [
                TextFormField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: t('change_password_current'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? t('change_password_current_required')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: t('change_password_new'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return t('change_password_too_short');
                    }
                    if (value == _currentController.text) {
                      return t('change_password_same_as_current');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: t('change_password_confirm'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value != _newController.text
                      ? t('change_password_mismatch')
                      : null,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t('change_password_submit')),
            ),
          ),
        ],
      ),
    );
  }
}
