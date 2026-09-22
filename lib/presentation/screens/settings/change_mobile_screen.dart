import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../core/theme/app_palette.dart';

/// Change the mobile number on the account.
///
/// The confirmation code goes to the NEW number, which is the only thing that
/// proves the user holds it.
class ChangeMobileScreen extends StatefulWidget {
  final UserRepository? userRepository;

  const ChangeMobileScreen({super.key, this.userRepository});

  @override
  State<ChangeMobileScreen> createState() => _ChangeMobileScreenState();
}

class _ChangeMobileScreenState extends State<ChangeMobileScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _codeSent = false;
  bool _isBusy = false;
  String? _error;

  UserRepository get _userRepository =>
      widget.userRepository ?? UserRepository();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _newPhoneNumber => _phoneController.text.trim();

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
    final languageProvider = context.read<LanguageProvider>();

    if (!_newPhoneNumber.startsWith('+') || _newPhoneNumber.length < 8) {
      setState(() => _error = languageProvider.t('change_mobile_invalid'));
      return;
    }

    await _run(() async {
      await _userRepository.requestMobileChangeOtp(_newPhoneNumber);
      if (mounted) {
        setState(() => _codeSent = true);
      }
    });
  }

  Future<void> _confirm() async {
    final languageProvider = context.read<LanguageProvider>();
    final otpCode = _otpController.text.trim();

    if (otpCode.isEmpty) {
      setState(() => _error = languageProvider.t('change_mobile_code_required'));
      return;
    }

    await _run(() async {
      await _userRepository.confirmMobileChange(
        newPhoneNumber: _newPhoneNumber,
        otpCode: otpCode,
      );

      if (!mounted) return;

      // The cached profile still holds the old number, so refresh it before
      // leaving the screen.
      await context.read<AuthProvider>().refreshUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(languageProvider.t('change_mobile_success'))),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final t = languageProvider.t;
    final currentNumber = authProvider.user?.phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(t('change_mobile_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('change_mobile_current'),
                    style: TextStyle(color: context.palette.textSecondary)),
                const SizedBox(height: 4),
                Text(currentNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  enabled: !_codeSent,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t('change_mobile_new'),
                    hintText: '+966500000000',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  Text(
                    t('change_mobile_code_sent',
                        args: {'phone': _newPhoneNumber}),
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: t('change_mobile_code'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
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
              onPressed: _isBusy ? null : (_codeSent ? _confirm : _sendCode),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_codeSent
                      ? t('change_mobile_confirm')
                      : t('change_mobile_send_code')),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isBusy
                  ? null
                  : () => setState(() {
                        _codeSent = false;
                        _otpController.clear();
                        _error = null;
                      }),
              child: Text(t('change_mobile_use_another_number')),
            ),
          ],
        ],
      ),
    );
  }
}
