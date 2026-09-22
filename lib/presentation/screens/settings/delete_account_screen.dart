import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../core/theme/app_palette.dart';

/// Delete the account, as required by App Store guideline 5.1.1(v).
///
/// The screen states plainly what is erased and what is kept, then asks for the
/// password when the account has one and a code sent to the number on file when
/// it does not.
class DeleteAccountScreen extends StatefulWidget {
  final UserRepository? userRepository;

  const DeleteAccountScreen({super.key, this.userRepository});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isBusy = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  String? _error;

  UserRepository get _userRepository =>
      widget.userRepository ?? UserRepository();

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _sendCode() async {
    await _run(() async {
      await _userRepository.requestDeleteAccountOtp();
      if (mounted) {
        setState(() => _codeSent = true);
      }
    });
  }

  /// The typed word must match the translated confirmation word, so the check
  /// works in Arabic as well as English.
  bool _confirmationTyped(LanguageProvider languageProvider) {
    final expected = languageProvider.t('delete_account_confirm_word');
    return _confirmController.text.trim().toUpperCase() ==
        expected.toUpperCase();
  }

  Future<void> _delete(bool hasPassword) async {
    final languageProvider = context.read<LanguageProvider>();

    if (!_confirmationTyped(languageProvider)) {
      setState(() =>
          _error = languageProvider.t('delete_account_confirm_word_required'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(languageProvider.t('delete_account_title')),
        content: Text(languageProvider.t('delete_account_final_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(languageProvider.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              languageProvider.t('delete_account_confirm'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _run(() async {
      await _userRepository.deleteAccount(
        password: hasPassword ? _passwordController.text : null,
        otpCode: hasPassword ? null : _otpController.text.trim(),
      );

      if (!mounted) return;

      final messagingProvider = context.read<MessagingProvider>();
      final authProvider = context.read<AuthProvider>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      await messagingProvider.disconnect();
      await authProvider.logout();

      messenger.showSnackBar(
        SnackBar(content: Text(languageProvider.t('delete_account_success'))),
      );
      navigator.popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final t = languageProvider.t;
    final hasPassword = authProvider.user?.hasPassword ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(t('delete_account_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  t('delete_account_warning'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildList(
            title: t('delete_account_erased_title'),
            icon: Icons.delete_outline,
            iconColor: AppColors.error,
            items: [
              t('delete_account_erased_profile'),
              t('delete_account_erased_health'),
              t('delete_account_erased_inbody'),
              t('delete_account_erased_plans'),
              t('delete_account_erased_notifications'),
            ],
          ),
          const SizedBox(height: 16),
          _buildList(
            title: t('delete_account_kept_title'),
            icon: Icons.inventory_2_outlined,
            iconColor: context.palette.textSecondary,
            items: [
              t('delete_account_kept_messages'),
              t('delete_account_kept_orders'),
            ],
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('delete_account_identity_title'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (hasPassword)
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: t('delete_account_password'),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  )
                else if (!_codeSent)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('delete_account_code_explainer'),
                        style:
                            TextStyle(color: context.palette.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isBusy ? null : _sendCode,
                        child: Text(t('delete_account_send_code')),
                      ),
                    ],
                  )
                else
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: t('delete_account_code'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  t('delete_account_type_to_confirm', args: {
                    'word': t('delete_account_confirm_word'),
                  }),
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    labelText: t('delete_account_confirm_word'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
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
            child: ElevatedButton.icon(
              onPressed: (_isBusy || (!hasPassword && !_codeSent))
                  ? null
                  : () => _delete(hasPassword),
              icon: _isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever),
              label: Text(t('delete_account_submit')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: context.palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
