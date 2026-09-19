import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/phone_number_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/international_phone_input.dart';
import 'forgot_password_screen.dart';

enum AuthStep { choose, phone, otp, email, emailSignup, completeRegistration }

enum PasswordLoginMode { email, phone }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthStep _step = AuthStep.choose;
  PasswordLoginMode _passwordLoginMode = PasswordLoginMode.email;
  int _resendCountdown = 60;
  bool _resendEnabled = false;
  int _otpAttempts = 3;
  int _signupResendCountdown = 60;
  bool _signupResendEnabled = false;
  bool _isSignupOtpSent = false;
  bool _isSendingSignupCode = false;
  bool _isCreatingSignupAccount = false;
  CountryPhoneOption _otpPhoneCountry = PhoneNumberUtils.defaultCountry;
  CountryPhoneOption _signupPhoneCountry = PhoneNumberUtils.defaultCountry;
  CountryPhoneOption _passwordLoginPhoneCountry =
      PhoneNumberUtils.defaultCountry;

  String? _otpPhoneErrorText;
  String? _signupPhoneErrorText;
  String? _passwordLoginPhoneErrorText;
  String? _signupVerificationErrorText;
  String? _signupNormalizedPhone;
  String? _completeNameErrorText;
  String? _completeEmailErrorText;
  String? _completePasswordErrorText;

  final TextEditingController _otpPhoneController = TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();
  final TextEditingController _signupConfirmPasswordController =
      TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();
  // The remaining sign-up questions, asked after a new phone number is verified.
  final TextEditingController _completeNameController = TextEditingController();
  final TextEditingController _completeEmailController =
      TextEditingController();
  final TextEditingController _completePasswordController =
      TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _signupOtpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _signupOtpFocusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _otpPhoneController.dispose();
    _loginEmailController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupPhoneController.dispose();
    _completeNameController.dispose();
    _completeEmailController.dispose();
    _completePasswordController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    for (final controller in _signupOtpControllers) {
      controller.dispose();
    }
    for (final node in _signupOtpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isOtpComplete =>
      _otpControllers.every((controller) => controller.text.length == 1);

  bool get _isSignupOtpComplete =>
      _signupOtpControllers.every((controller) => controller.text.length == 1);

  void _clearAuthErrors() {
    context.read<AuthProvider>().clearErrors();
  }

  void _clearPhoneErrors({
    bool clearSignup = false,
    bool clearPassword = false,
  }) {
    setState(() {
      if (clearSignup) {
        _signupPhoneErrorText = null;
      } else if (clearPassword) {
        _passwordLoginPhoneErrorText = null;
      } else {
        _otpPhoneErrorText = null;
      }
    });
    _clearAuthErrors();
  }

  String _invalidPhoneText(LanguageProvider languageProvider) {
    return languageProvider.t('auth_phone_invalid');
  }

  String? _normalizedPhoneOrSetError({
    required TextEditingController controller,
    required CountryPhoneOption country,
    required void Function(String? message) assignError,
  }) {
    final languageProvider = context.read<LanguageProvider>();
    final result = PhoneNumberUtils.normalize(
      rawInput: controller.text,
      country: country,
    );

    if (!result.isValid) {
      assignError(_invalidPhoneText(languageProvider));
      return null;
    }

    assignError(null);
    return result.normalizedPhone;
  }

  void _applyProviderPhoneError({
    required void Function(String? message) assignError,
  }) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.phoneFieldError != null) {
      setState(() {
        assignError(authProvider.phoneFieldError);
      });
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  void _applySignupInlineError() {
    final authProvider = context.read<AuthProvider>();
    setState(() {
      if (authProvider.phoneFieldError != null) {
        _signupPhoneErrorText = authProvider.phoneFieldError;
        _signupVerificationErrorText = null;
      } else {
        _signupVerificationErrorText = authProvider.error;
      }
    });
  }

  void _startResendCountdown() {
    setState(() {
      _resendEnabled = false;
      _resendCountdown = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _step != AuthStep.otp) {
        return false;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _resendEnabled = true;
        }
      });
      return _resendCountdown > 0;
    });
  }

  void _startSignupResendCountdown() {
    setState(() {
      _signupResendEnabled = false;
      _signupResendCountdown = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isSignupOtpSent || _step != AuthStep.emailSignup) {
        return false;
      }
      setState(() {
        _signupResendCountdown--;
        if (_signupResendCountdown <= 0) {
          _signupResendEnabled = true;
        }
      });
      return _signupResendCountdown > 0;
    });
  }

  void _resetOtpFields() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  void _resetSignupOtpFields() {
    for (final controller in _signupOtpControllers) {
      controller.clear();
    }
  }

  void _resetSignupVerificationState({bool keepPhoneError = false}) {
    _isSignupOtpSent = false;
    _signupNormalizedPhone = null;
    _signupVerificationErrorText = null;
    _signupResendEnabled = false;
    _signupResendCountdown = 60;
    if (!keepPhoneError) {
      _signupPhoneErrorText = null;
    }
    _resetSignupOtpFields();
  }

  void _onSignupPhoneChanged() {
    _resetSignupVerificationState();
    _clearAuthErrors();
  }

  String? _validateSignupFormAndNormalizePhone() {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;
    final name = _signupNameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        name.isEmpty) {
      _showError(languageProvider.t('auth_missing_fields'));
      return null;
    }

    if (!email.contains('@')) {
      _showError(languageProvider.t('auth_invalid_email'));
      return null;
    }

    if (password != confirmPassword) {
      _showError(languageProvider.t('auth_password_mismatch'));
      return null;
    }

    final normalizedPhone = _normalizedPhoneOrSetError(
      controller: _signupPhoneController,
      country: _signupPhoneCountry,
      assignError: (message) => _signupPhoneErrorText = message,
    );

    if (normalizedPhone == null) {
      setState(() {
        _signupVerificationErrorText = null;
      });
      return null;
    }

    if (authProvider.error != null || authProvider.phoneFieldError != null) {
      authProvider.clearErrors();
    }

    return normalizedPhone;
  }

  Future<void> _sendSignupCode() async {
    if (_isSendingSignupCode || _isCreatingSignupAccount) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final normalizedPhone = _validateSignupFormAndNormalizePhone();
    if (normalizedPhone == null) {
      return;
    }

    setState(() {
      _isSendingSignupCode = true;
      _signupVerificationErrorText = null;
      _signupPhoneErrorText = null;
    });

    final success = await authProvider.requestOTP(normalizedPhone);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingSignupCode = false;
    });

    if (success) {
      setState(() {
        _isSignupOtpSent = true;
        _signupNormalizedPhone = normalizedPhone;
        _signupVerificationErrorText = null;
        _signupPhoneErrorText = null;
        _resetSignupOtpFields();
      });
      _startSignupResendCountdown();
      _signupOtpFocusNodes.first.requestFocus();
      return;
    }

    _applySignupInlineError();
  }

  /// Continue from the phone step.
  ///
  /// A number that already has an account signs in with its password; only a new
  /// number is sent a code. Previously every number was sent an OTP, so a
  /// registered user could sign in without their password.
  Future<void> _continueWithPhone() async {
    final authProvider = context.read<AuthProvider>();
    final normalizedPhone = _normalizedPhoneOrSetError(
      controller: _otpPhoneController,
      country: _otpPhoneCountry,
      assignError: (message) => _otpPhoneErrorText = message,
    );

    if (normalizedPhone == null) {
      setState(() {});
      return;
    }

    final status = await authProvider.checkPhone(normalizedPhone);
    if (!mounted) return;

    if (status == null) {
      _applyProviderPhoneError(
        assignError: (message) => _otpPhoneErrorText = message,
      );
      return;
    }

    if (status.registered && status.hasPassword) {
      // Hand over to the existing phone + password login step.
      setState(() {
        _passwordLoginMode = PasswordLoginMode.phone;
        _passwordLoginPhoneCountry = _otpPhoneCountry;
        _loginPhoneController.text = _otpPhoneController.text;
        _step = AuthStep.email;
      });
      return;
    }

    // New number, or one verified by OTP that never finished signing up.
    await _requestOTP(normalizedPhone);
  }

  Future<void> _requestOTP([String? phone]) async {
    final authProvider = context.read<AuthProvider>();
    final normalizedPhone = phone ??
        _normalizedPhoneOrSetError(
          controller: _otpPhoneController,
          country: _otpPhoneCountry,
          assignError: (message) => _otpPhoneErrorText = message,
        );

    if (normalizedPhone == null) {
      setState(() {});
      return;
    }

    final success =
        await authProvider.requestOTP(normalizedPhone, purpose: 'signup');
    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _step = AuthStep.otp;
        _otpAttempts = 3;
      });
      _startResendCountdown();
      _otpFocusNodes[0].requestFocus();
    } else {
      _applyProviderPhoneError(
        assignError: (message) => _otpPhoneErrorText = message,
      );
    }
  }

  Future<void> _verifyOTP() async {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final normalizedPhone = _normalizedPhoneOrSetError(
      controller: _otpPhoneController,
      country: _otpPhoneCountry,
      assignError: (message) => _otpPhoneErrorText = message,
    );
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (normalizedPhone == null) {
      setState(() {});
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showError(languageProvider.t('otp_incomplete'));
      return;
    }

    final success = await authProvider.verifyOTP(normalizedPhone, otp);
    if (!mounted) {
      return;
    }

    if (success) {
      // A brand-new account has not given a name, email or password yet.
      if (!authProvider.registrationComplete) {
        setState(() => _step = AuthStep.completeRegistration);
        return;
      }
      widget.onAuthenticated();
      return;
    }

    _applyProviderPhoneError(
      assignError: (message) => _otpPhoneErrorText = message,
    );
    _resetOtpFields();
    _otpFocusNodes[0].requestFocus();
    setState(() {
      _otpAttempts = _otpAttempts > 0 ? _otpAttempts - 1 : 0;
    });
  }

  /// Submit the remaining sign-up answers for an account created by OTP.
  Future<void> _submitCompleteRegistration() async {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();

    final name = _completeNameController.text.trim();
    final email = _completeEmailController.text.trim();
    final password = _completePasswordController.text;

    setState(() {
      _completeNameErrorText =
          name.isEmpty ? languageProvider.t('auth_name_required') : null;
      _completePasswordErrorText = password.length < 8
          ? languageProvider.t('auth_password_min_length')
          : null;
      // Email is optional here; the account is identified by its phone number.
      _completeEmailErrorText = email.isNotEmpty && !email.contains('@')
          ? languageProvider.t('auth_email_invalid')
          : null;
    });

    if (_completeNameErrorText != null ||
        _completePasswordErrorText != null ||
        _completeEmailErrorText != null) {
      return;
    }

    final ok = await authProvider.completeRegistration(
      fullName: name,
      password: password,
      email: email.isEmpty ? null : email,
    );
    if (!mounted) return;

    if (ok) {
      widget.onAuthenticated();
      return;
    }

    if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  Future<void> _handleEmailLogin() async {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final password = _loginPasswordController.text;

    if (password.isEmpty) {
      _showError(languageProvider.t('auth_missing_fields'));
      return;
    }

    late final String emailOrPhone;
    if (_passwordLoginMode == PasswordLoginMode.email) {
      final email = _loginEmailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _showError(languageProvider.t('auth_invalid_email'));
        return;
      }
      emailOrPhone = email;
    } else {
      final normalizedPhone = _normalizedPhoneOrSetError(
        controller: _loginPhoneController,
        country: _passwordLoginPhoneCountry,
        assignError: (message) => _passwordLoginPhoneErrorText = message,
      );
      if (normalizedPhone == null) {
        setState(() {});
        return;
      }
      emailOrPhone = normalizedPhone;
    }

    final success = await authProvider.loginWithEmailOrPhone(
      emailOrPhone: emailOrPhone,
      password: password,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      widget.onAuthenticated();
      return;
    }

    if (_passwordLoginMode == PasswordLoginMode.phone) {
      _applyProviderPhoneError(
        assignError: (message) => _passwordLoginPhoneErrorText = message,
      );
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  Future<void> _handleEmailSignup() async {
    if (_isCreatingSignupAccount || _isSendingSignupCode) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final normalizedPhone =
        _signupNormalizedPhone ?? _validateSignupFormAndNormalizePhone();
    final otpCode =
        _signupOtpControllers.map((controller) => controller.text).join();

    if (normalizedPhone == null) {
      return;
    }

    if (!_isSignupOtpSent || !RegExp(r'^\d{6}$').hasMatch(otpCode)) {
      _showError(languageProvider.t('otp_incomplete'));
      return;
    }

    setState(() {
      _isCreatingSignupAccount = true;
      _signupVerificationErrorText = null;
    });

    final success = await authProvider.signup(
      name: _signupNameController.text.trim(),
      email: _signupEmailController.text.trim(),
      phone: normalizedPhone,
      password: _signupPasswordController.text,
      otpCode: otpCode,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreatingSignupAccount = false;
    });

    if (success) {
      widget.onAuthenticated();
      return;
    }

    _applySignupInlineError();
  }

  Future<void> _handleSocialLogin(String provider) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.socialLogin(provider);
    if (!mounted) {
      return;
    }

    if (success) {
      widget.onAuthenticated();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _handleBackgroundImageError(Object exception, StackTrace? stackTrace) {}

  Future<void> _openForgotPassword() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
    if (result == true && mounted) {
      widget.onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isRTL = languageProvider.isArabic;
    final isBusy = authProvider.isLoading ||
        _isSendingSignupCode ||
        _isCreatingSignupAccount;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const NetworkImage(
                  'https://images.unsplash.com/photo-1689007669034-9ef988d89742?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                ),
                fit: BoxFit.cover,
                onError: _handleBackgroundImageError,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/logo_primary.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedReveal(
                          offset: Offset(isRTL ? -0.25 : 0.25, 0),
                          duration: const Duration(milliseconds: 650),
                          child: Text(
                            languageProvider.t('auth_app_name'),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 120),
                          offset: Offset(isRTL ? -0.2 : 0.2, 0),
                          duration: const Duration(milliseconds: 650),
                          child: Text(
                            languageProvider.t('auth_tagline'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Card(
                        elevation: 2,
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.large),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _step == AuthStep.otp ||
                                        (_step == AuthStep.emailSignup &&
                                            _isSignupOtpSent)
                                    ? languageProvider.t('auth_enter_otp')
                                    : _step == AuthStep.emailSignup
                                        ? languageProvider
                                            .t('auth_create_account')
                                        : languageProvider.t('auth_welcome'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _step == AuthStep.otp
                                    ? '${languageProvider.t('auth_otp_sent')} ${_otpPhoneController.text.trim()}'
                                    : _step == AuthStep.choose
                                        ? languageProvider
                                            .t('auth_welcome_subtitle')
                                        : _step == AuthStep.phone
                                            ? languageProvider.t(
                                                'auth_phone_will_receive_otp',
                                              )
                                            : _step == AuthStep.emailSignup &&
                                                    _isSignupOtpSent
                                                ? '${languageProvider.t('auth_otp_sent')} ${_signupPhoneController.text.trim()}'
                                                : _step == AuthStep.emailSignup
                                                    ? languageProvider.t(
                                                        'auth_create_account_subtitle',
                                                      )
                                                    : languageProvider.t(
                                                        'auth_welcome_subtitle',
                                                      ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_step == AuthStep.choose) ...[
                                OutlinedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () => setState(
                                          () => _step = AuthStep.email),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    alignment: isRTL
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.medium),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.textPrimary,
                                  ),
                                  label: Text(
                                    languageProvider
                                        .t('auth_continue_with_email'),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () => setState(
                                          () => _step = AuthStep.phone),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    alignment: isRTL
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.medium),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.textPrimary,
                                  ),
                                  label: Text(
                                    languageProvider
                                        .t('auth_continue_with_phone'),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        languageProvider.t('auth_or_divider'),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _socialIconButton(
                                      icon: Icons.g_mobiledata,
                                      color: const Color(0xFF4285F4),
                                      onPressed: isBusy
                                          ? null
                                          : () => _handleSocialLogin('google'),
                                    ),
                                    const SizedBox(width: 16),
                                    _socialIconButton(
                                      icon: Icons.facebook,
                                      color: const Color(0xFF1877F2),
                                      onPressed: isBusy
                                          ? null
                                          : () =>
                                              _handleSocialLogin('facebook'),
                                    ),
                                    const SizedBox(width: 16),
                                    _socialIconButton(
                                      icon: Icons.apple,
                                      color: Colors.black,
                                      onPressed: isBusy
                                          ? null
                                          : () => _handleSocialLogin('apple'),
                                    ),
                                  ],
                                ),
                              ],
                              if (_step == AuthStep.email) ...[
                                _buildLoginModeSelector(languageProvider),
                                const SizedBox(height: 12),
                                if (_passwordLoginMode ==
                                    PasswordLoginMode.email)
                                  _buildLabeledInput(
                                    label: languageProvider.t('auth_email'),
                                    hint: languageProvider
                                        .t('auth_email_placeholder'),
                                    controller: _loginEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (_) => _clearAuthErrors(),
                                  )
                                else
                                  InternationalPhoneInput(
                                    label: languageProvider.t('auth_phone'),
                                    hint: languageProvider
                                        .t('auth_phone_placeholder'),
                                    controller: _loginPhoneController,
                                    selectedCountry: _passwordLoginPhoneCountry,
                                    onCountryChanged: (country) {
                                      setState(() {
                                        _passwordLoginPhoneCountry = country;
                                        _passwordLoginPhoneErrorText = null;
                                      });
                                      _clearAuthErrors();
                                    },
                                    onChanged: (_) =>
                                        _clearPhoneErrors(clearPassword: true),
                                    enabled: !isBusy,
                                    errorText: _passwordLoginPhoneErrorText,
                                  ),
                                const SizedBox(height: 12),
                                _buildLabeledInput(
                                  label: languageProvider.t('auth_password'),
                                  hint: languageProvider.t(
                                    'auth_password_placeholder',
                                  ),
                                  controller: _loginPasswordController,
                                  obscureText: true,
                                  onChanged: (_) => _clearAuthErrors(),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  languageProvider
                                      .t('auth_coach_default_password_help'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: isBusy
                                        ? null
                                        : _openForgotPassword,
                                    child: Text(
                                      languageProvider
                                          .t('auth_forgot_password'),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: isBusy ? null : _handleEmailLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          languageProvider.t('auth_sign_in')),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => setState(
                                          () => _step = AuthStep.choose),
                                  child: Text(languageProvider.t('auth_back')),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => setState(
                                              () =>
                                                  _step = AuthStep.emailSignup,
                                            ),
                                    child: Text(
                                      '${languageProvider.t('auth_no_account')} ${languageProvider.t('auth_sign_up')}',
                                    ),
                                  ),
                                ),
                              ],
                              if (_step == AuthStep.emailSignup) ...[
                                _buildLabeledInput(
                                  label: languageProvider.t('auth_full_name'),
                                  hint: languageProvider.t('auth_full_name'),
                                  controller: _signupNameController,
                                  onChanged: (_) => _clearAuthErrors(),
                                ),
                                const SizedBox(height: 12),
                                _buildLabeledInput(
                                  label: languageProvider.t('auth_email'),
                                  hint: languageProvider
                                      .t('auth_email_placeholder'),
                                  controller: _signupEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (_) => _clearAuthErrors(),
                                ),
                                const SizedBox(height: 12),
                                InternationalPhoneInput(
                                  label: languageProvider.t('auth_phone'),
                                  hint: languageProvider
                                      .t('auth_phone_placeholder'),
                                  controller: _signupPhoneController,
                                  selectedCountry: _signupPhoneCountry,
                                  onCountryChanged: (country) {
                                    setState(() {
                                      _signupPhoneCountry = country;
                                      _onSignupPhoneChanged();
                                    });
                                  },
                                  onChanged: (_) {
                                    setState(_onSignupPhoneChanged);
                                  },
                                  enabled: !_isSendingSignupCode &&
                                      !_isCreatingSignupAccount,
                                  errorText: _signupPhoneErrorText,
                                ),
                                const SizedBox(height: 12),
                                _buildLabeledInput(
                                  label: languageProvider.t('auth_password'),
                                  hint: languageProvider.t(
                                    'auth_password_placeholder',
                                  ),
                                  controller: _signupPasswordController,
                                  obscureText: true,
                                  onChanged: (_) => _clearAuthErrors(),
                                ),
                                const SizedBox(height: 12),
                                _buildLabeledInput(
                                  label: languageProvider.t(
                                    'auth_confirm_password',
                                  ),
                                  hint: languageProvider.t(
                                    'auth_confirm_password_placeholder',
                                  ),
                                  controller: _signupConfirmPasswordController,
                                  obscureText: true,
                                  onChanged: (_) => _clearAuthErrors(),
                                ),
                                const SizedBox(height: 16),
                                if (!_isSignupOtpSent) ...[
                                  ElevatedButton(
                                    onPressed: isBusy ? null : _sendSignupCode,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: _isSendingSignupCode
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            languageProvider
                                                .t('auth_send_code'),
                                          ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.medium),
                                      border: Border.all(
                                        color: AppColors.success.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: AppColors.success,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            languageProvider.t(
                                              'auth_signup_code_sent_help',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildOtpInputs(
                                    controllers: _signupOtpControllers,
                                    focusNodes: _signupOtpFocusNodes,
                                    enabled: !isBusy,
                                    onCompleted: _handleEmailSignup,
                                  ),
                                  if (_signupVerificationErrorText != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _signupVerificationErrorText!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: isBusy || !_isSignupOtpComplete
                                        ? null
                                        : _handleEmailSignup,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: _isCreatingSignupAccount
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            languageProvider
                                                .t('auth_create_account'),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _signupResendEnabled && !isBusy
                                        ? _sendSignupCode
                                        : null,
                                    child: Text(
                                      _signupResendEnabled
                                          ? languageProvider.t('auth_resend')
                                          : '${languageProvider.t('auth_resend_in')} $_signupResendCountdown',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isBusy
                                        ? null
                                        : () {
                                            setState(() {
                                              _resetSignupVerificationState();
                                            });
                                          },
                                    child: Text(
                                      languageProvider.t('auth_change_phone'),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => setState(() {
                                            _resetSignupVerificationState();
                                            _step = AuthStep.email;
                                          }),
                                  child: Text(languageProvider.t('auth_back')),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => setState(() {
                                              _resetSignupVerificationState();
                                              _step = AuthStep.email;
                                            }),
                                    child: Text(
                                      '${languageProvider.t('auth_have_account')} ${languageProvider.t('auth_sign_in')}',
                                    ),
                                  ),
                                ),
                              ],
                              if (_step == AuthStep.phone) ...[
                                InternationalPhoneInput(
                                  label: languageProvider.t('auth_phone'),
                                  hint: languageProvider
                                      .t('auth_phone_placeholder'),
                                  controller: _otpPhoneController,
                                  selectedCountry: _otpPhoneCountry,
                                  onCountryChanged: (country) {
                                    setState(() {
                                      _otpPhoneCountry = country;
                                      _otpPhoneErrorText = null;
                                    });
                                    _clearAuthErrors();
                                  },
                                  onChanged: (_) => _clearPhoneErrors(),
                                  enabled: !isBusy,
                                  errorText: _otpPhoneErrorText,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: isBusy ? null : _continueWithPhone,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      // Neutral, because this either sends a
                                      // code or moves to a password prompt.
                                      : Text(
                                          languageProvider.t('auth_continue')),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => setState(
                                          () => _step = AuthStep.choose),
                                  child: Text(languageProvider.t('auth_back')),
                                ),
                              ],
                              if (_step == AuthStep.otp) ...[
                                InternationalPhoneInput(
                                  label: languageProvider.t('auth_phone'),
                                  hint: languageProvider
                                      .t('auth_phone_placeholder'),
                                  controller: _otpPhoneController,
                                  selectedCountry: _otpPhoneCountry,
                                  onCountryChanged: (country) {
                                    setState(() {
                                      _otpPhoneCountry = country;
                                      _otpPhoneErrorText = null;
                                    });
                                    _clearAuthErrors();
                                  },
                                  onChanged: (_) => _clearPhoneErrors(),
                                  enabled: !isBusy,
                                  errorText: _otpPhoneErrorText,
                                ),
                                const SizedBox(height: 16),
                                _buildOtpInputs(
                                  controllers: _otpControllers,
                                  focusNodes: _otpFocusNodes,
                                  enabled: !isBusy,
                                  onCompleted: _verifyOTP,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: isBusy || !_isOtpComplete
                                      ? null
                                      : _verifyOTP,
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(languageProvider.t('auth_verify')),
                                ),
                                if (_otpAttempts < 3) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_otpAttempts ${languageProvider.t('auth_attempts_remaining')}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _resendEnabled && !isBusy
                                      ? () => _requestOTP()
                                      : null,
                                  child: Text(
                                    _resendEnabled
                                        ? languageProvider.t('auth_resend')
                                        : '${languageProvider.t('auth_resend_in')} $_resendCountdown',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isBusy
                                      ? null
                                      : () {
                                          setState(() {
                                            _step = AuthStep.phone;
                                            _otpPhoneErrorText = null;
                                            _resetOtpFields();
                                          });
                                        },
                                  child: Text(
                                    languageProvider.t('auth_change_phone'),
                                  ),
                                ),
                              ],
                              // The remaining sign-up questions, asked after a
                              // new number is verified by OTP.
                              if (_step == AuthStep.completeRegistration) ...[
                                Text(
                                  languageProvider.t('auth_complete_profile_desc'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _completeNameController,
                                  enabled: !isBusy,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.t('auth_full_name'),
                                    border: const OutlineInputBorder(),
                                    errorText: _completeNameErrorText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _completeEmailController,
                                  enabled: !isBusy,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText:
                                        languageProvider.t('auth_email_optional'),
                                    border: const OutlineInputBorder(),
                                    errorText: _completeEmailErrorText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _completePasswordController,
                                  enabled: !isBusy,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.t('auth_password'),
                                    helperText: languageProvider
                                        .t('auth_password_min_length'),
                                    border: const OutlineInputBorder(),
                                    errorText: _completePasswordErrorText,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed:
                                      isBusy ? null : _submitCompleteRegistration,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: isBusy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(languageProvider.t('auth_finish')),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isRTL) const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginModeSelector(LanguageProvider languageProvider) {
    final selectedColor = AppColors.primary.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLoginModeButton(
              label: languageProvider.t('auth_email'),
              isSelected: _passwordLoginMode == PasswordLoginMode.email,
              selectedColor: selectedColor,
              onTap: () {
                setState(() {
                  _passwordLoginMode = PasswordLoginMode.email;
                  _passwordLoginPhoneErrorText = null;
                });
                _clearAuthErrors();
              },
            ),
          ),
          Expanded(
            child: _buildLoginModeButton(
              label: languageProvider.t('auth_phone'),
              isSelected: _passwordLoginMode == PasswordLoginMode.phone,
              selectedColor: selectedColor,
              onTap: () {
                setState(() {
                  _passwordLoginMode = PasswordLoginMode.phone;
                });
                _clearAuthErrors();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginModeButton({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputs({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required bool enabled,
    required Future<void> Function() onCompleted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 42,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            enabled: enabled,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }
              setState(() {});
              final isComplete = controllers
                  .every((controller) => controller.text.length == 1);
              if (index == 5 && value.isNotEmpty && isComplete) {
                onCompleted();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _socialIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.all(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildLabeledInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
