
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/config/demo_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/animated_reveal.dart';

enum AuthStep { choose, phone, otp, email, emailSignup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthStep _step = AuthStep.choose;
  bool _isPhoneValid = false;
  int _resendCountdown = 60;
  bool _resendEnabled = false;
  int _otpAttempts = 3;
  DateTime? _logoPressStart;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _signupPhoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isValidSaudiPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    final regex = RegExp(r'^\+9665\d{8}$');
    return regex.hasMatch(cleaned);
  }

  void _updatePhoneValidity(String value) {
    setState(() {
      _isPhoneValid = _isValidSaudiPhone(value);
    });
  }
  void _startResendCountdown() {
    setState(() {
      _resendEnabled = false;
      _resendCountdown = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _resendEnabled = true;
        }
      });
      return _resendCountdown > 0;
    });
  }

  Future<void> _requestOTP() async {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final phone = _phoneController.text.trim();

    if (!_isValidSaudiPhone(phone)) {
      _showError(languageProvider.t('otp_invalid_phone'));
      return;
    }

    final success = await authProvider.requestOTP(phone);
    if (!mounted) return;

    if (success) {
      setState(() {
        _step = AuthStep.otp;
      });
      _startResendCountdown();
      _otpFocusNodes[0].requestFocus();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  Future<void> _verifyOTP() async {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final phone = _phoneController.text.trim();
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 6) {
      _showError(languageProvider.t('otp_incomplete'));
      return;
    }

    final success = await authProvider.verifyOTP(phone, otp);
    if (!mounted) return;

    if (success) {
      widget.onAuthenticated();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
      setState(() {
        _otpAttempts = _otpAttempts > 0 ? _otpAttempts - 1 : 0;
      });
    }
  }
  Future<void> _handleEmailLogin() async {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final emailOrPhone = _emailController.text.trim();
    final password = _passwordController.text;

    if (emailOrPhone.isEmpty || password.isEmpty) {
      _showError(languageProvider.t('auth_missing_fields'));
      return;
    }

    final success = await authProvider.loginWithEmailOrPhone(
      emailOrPhone: emailOrPhone,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      widget.onAuthenticated();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  Future<void> _handleEmailSignup() async {
    final authProvider = context.read<AuthProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final email = _emailController.text.trim();
    final phone = _signupPhoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        name.isEmpty) {
      _showError(languageProvider.t('auth_missing_fields'));
      return;
    }

    if (password != confirmPassword) {
      _showError(languageProvider.t('auth_password_mismatch'));
      return;
    }

    final success = await authProvider.signup(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      widget.onAuthenticated();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.socialLogin(provider);
    if (!mounted) return;

    if (success) {
      widget.onAuthenticated();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  void _tryDemo() {
    final authProvider = context.read<AuthProvider>();
    if (DemoConfig.isDemo) {
      authProvider.setDemoRole('user');
      widget.onAuthenticated();
    } else {
      _showError(context.read<LanguageProvider>().t('auth_demo_unavailable'));
    }
  }

  void _handleLogoPress() {
    _logoPressStart = DateTime.now();
  }

  void _handleLogoRelease() {
    final start = _logoPressStart;
    _logoPressStart = null;
    if (start == null) return;
    if (DateTime.now().difference(start).inSeconds >= 2) {
      _tryDemo();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _handleBackgroundImageError(Object exception, StackTrace? stackTrace) {}

  void _showForgotPasswordDialog() {
    final languageProvider = context.read<LanguageProvider>();
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.t('auth_forgot_password_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(languageProvider.t('auth_forgot_password_desc')),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: languageProvider.t('auth_email_or_phone'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.t('auth_cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(languageProvider.t('auth_reset_link_sent')),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(languageProvider.t('auth_send')),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isRTL = languageProvider.isArabic;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1689007669034-9ef988d89742?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                ),
                fit: BoxFit.cover,
                onError: _handleBackgroundImageError,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.2)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTapDown: (_) => _handleLogoPress(),
                      onTapUp: (_) => _handleLogoRelease(),
                      onTapCancel: _handleLogoRelease,
                      child: Column(
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
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _step == AuthStep.otp
                                  ? languageProvider.t('auth_enter_otp')
                                  : _step == AuthStep.emailSignup
                                      ? languageProvider.t('auth_create_account')
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
                                  ? '${languageProvider.t('auth_otp_sent')} ${_phoneController.text}'
                                  : _step == AuthStep.choose
                                      ? languageProvider.t('auth_welcome_subtitle')
                                      : _step == AuthStep.phone
                                          ? languageProvider.t('auth_phone_will_receive_otp')
                                          : _step == AuthStep.emailSignup
                                              ? languageProvider.t('auth_create_account_subtitle')
                                              : languageProvider.t('auth_welcome_subtitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_step == AuthStep.choose) ...[
                              OutlinedButton.icon(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => setState(() => _step = AuthStep.email),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.centerLeft,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.medium),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.textPrimary,
                                ),
                                label: Text(
                                  languageProvider.t('auth_continue_with_email'),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => setState(() => _step = AuthStep.phone),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.centerLeft,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.medium),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  color: AppColors.textPrimary,
                                ),
                                label: Text(
                                  languageProvider.t('auth_continue_with_phone'),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () => _handleSocialLogin('google'),
                                  ),
                                  const SizedBox(width: 16),
                                  _socialIconButton(
                                    icon: Icons.facebook,
                                    color: const Color(0xFF1877F2),
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () => _handleSocialLogin('facebook'),
                                  ),
                                  const SizedBox(width: 16),
                                  _socialIconButton(
                                    icon: Icons.apple,
                                    color: Colors.black,
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () => _handleSocialLogin('apple'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: OutlinedButton(
                                  onPressed: authProvider.isLoading ? null : _tryDemo,
                                  child: Text(languageProvider.t('auth_try_demo')),
                                ),
                              ),
                            ],
                            if (_step == AuthStep.email) ...[
                              _buildLabeledInput(
                                label: languageProvider.t('auth_email_or_phone'),
                                hint: languageProvider.t('auth_email_or_phone_placeholder'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildLabeledInput(
                                label: languageProvider.t('auth_password'),
                                hint: languageProvider.t('auth_password_placeholder'),
                                controller: _passwordController,
                                obscureText: true,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: authProvider.isLoading ? null : _showForgotPasswordDialog,
                                  child: Text(languageProvider.t('auth_forgot_password')),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleEmailLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(languageProvider.t('auth_sign_in')),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => setState(() => _step = AuthStep.choose),
                                child: Text(languageProvider.t('auth_back')),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : () => setState(() => _step = AuthStep.emailSignup),
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
                                controller: _nameController,
                              ),
                              const SizedBox(height: 12),
                              _buildLabeledInput(
                                label: languageProvider.t('auth_email'),
                                hint: languageProvider.t('auth_email_placeholder'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildLabeledInput(
                                label: languageProvider.t('auth_phone'),
                                hint: languageProvider.t('auth_phone_placeholder'),
                                controller: _signupPhoneController,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _buildLabeledInput(
                                label: languageProvider.t('auth_password'),
                                hint: languageProvider.t('auth_password_placeholder'),
                                controller: _passwordController,
                                obscureText: true,
                              ),
                              const SizedBox(height: 12),
                              _buildLabeledInput(
                                label: languageProvider.t('auth_confirm_password'),
                                hint: languageProvider.t('auth_confirm_password_placeholder'),
                                controller: _confirmPasswordController,
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleEmailSignup,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(languageProvider.t('auth_create_account')),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => setState(() => _step = AuthStep.email),
                                child: Text(languageProvider.t('auth_back')),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : () => setState(() => _step = AuthStep.email),
                                  child: Text(
                                    '${languageProvider.t('auth_have_account')} ${languageProvider.t('auth_sign_in')}',
                                  ),
                                ),
                              ),
                            ],
                            if (_step == AuthStep.phone) ...[
                              _buildLabeledInput(
                                label: languageProvider.t('auth_phone'),
                                hint: languageProvider.t('auth_phone_placeholder'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                onChanged: _updatePhoneValidity,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: authProvider.isLoading || !_isPhoneValid
                                    ? null
                                    : _requestOTP,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(languageProvider.t('auth_sign_in')),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => setState(() => _step = AuthStep.choose),
                                child: Text(languageProvider.t('auth_back')),
                              ),
                            ],
                            if (_step == AuthStep.otp) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  return SizedBox(
                                    width: 42,
                                    child: TextField(
                                      controller: _otpControllers[index],
                                      focusNode: _otpFocusNodes[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
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
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        if (value.isNotEmpty && index < 5) {
                                          _otpFocusNodes[index + 1].requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          _otpFocusNodes[index - 1].requestFocus();
                                        }
                                        if (index == 5 && value.isNotEmpty) {
                                          _verifyOTP();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _verifyOTP,
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(languageProvider.t('auth_verify')),
                              ),
                              if (_otpAttempts < 3) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${_otpAttempts} ${languageProvider.t('auth_attempts_remaining')}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _resendEnabled ? _requestOTP : null,
                                child: Text(
                                  _resendEnabled
                                      ? languageProvider.t('auth_resend')
                                      : '${languageProvider.t('auth_resend_in')} $_resendCountdown',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _step = AuthStep.phone;
                                    for (final controller in _otpControllers) {
                                      controller.clear();
                                    }
                                  });
                                },
                                child: Text(languageProvider.t('auth_change_phone')),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      languageProvider.t('auth_demo_credentials'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageProvider.t('auth_demo_user'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      languageProvider.t(
                        'auth_demo_credentials_detail',
                        args: {
                          'email': 'user@fitcoach.com',
                          'password': languageProvider.t('auth_demo_password_any'),
                        },
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageProvider.t('auth_demo_coach'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      languageProvider.t(
                        'auth_demo_credentials_detail',
                        args: {
                          'email': 'coach@fitcoach.com',
                          'password': languageProvider.t('auth_demo_password_any'),
                        },
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageProvider.t('auth_demo_admin'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      languageProvider.t(
                        'auth_demo_credentials_detail',
                        args: {
                          'email': 'admin@fitcoach.com',
                          'password': languageProvider.t('auth_demo_password_any'),
                        },
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
