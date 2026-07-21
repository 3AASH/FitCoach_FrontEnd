import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/phone_number_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/international_phone_input.dart';

/// Phone-OTP password reset flow:
/// 1. enter phone number -> send a verification code
/// 2. enter the code + a new password -> reset and sign in
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  CountryPhoneOption _country = PhoneNumberUtils.defaultCountry;
  bool _codeSent = false;
  String? _normalizedPhone;
  String? _phoneError;
  String? _formError;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final languageProvider = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();

    final result = PhoneNumberUtils.normalize(
      rawInput: _phoneController.text,
      country: _country,
    );
    if (!result.isValid) {
      setState(() => _phoneError = languageProvider.t('auth_phone_invalid'));
      return;
    }
    setState(() {
      _phoneError = null;
      _formError = null;
    });

    final ok = await authProvider.requestOTP(result.normalizedPhone);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _codeSent = true;
        _normalizedPhone = result.normalizedPhone;
      });
    }
  }

  Future<void> _resetPassword() async {
    final languageProvider = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();

    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (otp.length != 6) {
      setState(() => _formError = languageProvider.t('auth_enter_otp'));
      return;
    }
    if (password.length < 8) {
      setState(
          () => _formError = languageProvider.t('auth_password_too_short'));
      return;
    }
    if (password != confirm) {
      setState(
          () => _formError = languageProvider.t('auth_passwords_no_match'));
      return;
    }
    setState(() => _formError = null);

    final ok = await authProvider.resetPassword(
      phoneNumber: _normalizedPhone!,
      otpCode: otp,
      newPassword: password,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.t('auth_reset_success')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isBusy = authProvider.isLoading;
    final providerError = authProvider.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('auth_forgot_password_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codeSent
                    ? languageProvider.t('auth_enter_otp')
                    : languageProvider.t('auth_reset_password_phone_desc'),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              if (!_codeSent) ...[
                InternationalPhoneInput(
                  controller: _phoneController,
                  selectedCountry: _country,
                  onCountryChanged: (c) => setState(() => _country = c),
                  label: languageProvider.t('auth_phone'),
                  errorText: _phoneError,
                  enabled: !isBusy,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isBusy ? null : _sendCode,
                  child: isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(languageProvider.t('auth_send_code')),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: languageProvider.t('auth_enter_otp'),
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  enabled: !isBusy,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: languageProvider.t('auth_new_password'),
                    border: const OutlineInputBorder(),
                  ),
                  enabled: !isBusy,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: languageProvider.t('auth_confirm_password'),
                    border: const OutlineInputBorder(),
                  ),
                  enabled: !isBusy,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isBusy ? null : _resetPassword,
                  child: isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(languageProvider.t('auth_reset_password_action')),
                ),
              ],
              if (_formError != null || providerError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _formError ?? providerError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
