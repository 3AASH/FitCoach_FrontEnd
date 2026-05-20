import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/phone_number_utils.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/international_phone_input.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback onNavigateToLogin;

  const SignupScreen({
    super.key,
    required this.onAuthenticated,
    required this.onNavigateToLogin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isOtpSent = false;
  bool _isSendingCode = false;
  bool _isCreatingAccount = false;
  bool _resendEnabled = false;
  int _resendCountdown = 60;
  CountryPhoneOption _selectedCountry = PhoneNumberUtils.defaultCountry;
  String? _phoneErrorText;
  String? _verificationErrorText;
  String? _normalizedPhone;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendEnabled = false;
      _resendCountdown = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isOtpSent) {
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

  void _resetOtpState() {
    _isOtpSent = false;
    _resendEnabled = false;
    _resendCountdown = 60;
    _verificationErrorText = null;
    _normalizedPhone = null;
    _otpController.clear();
  }

  String? _validateAndNormalizePhone(bool isArabic) {
    final normalizedPhone = PhoneNumberUtils.normalize(
      rawInput: _phoneController.text,
      country: _selectedCountry,
    );

    if (!normalizedPhone.isValid) {
      setState(() {
        _phoneErrorText =
            isArabic ? 'أدخل رقم هاتف صالحاً' : 'Enter a valid phone number';
      });
      return null;
    }

    return normalizedPhone.normalizedPhone;
  }

  Future<void> _sendCode(bool isArabic) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'الرجاء الموافقة على الشروط والأحكام'
                : 'Please agree to Terms & Conditions',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final normalizedPhone = _validateAndNormalizePhone(isArabic);
    if (normalizedPhone == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    setState(() {
      _isSendingCode = true;
      _phoneErrorText = null;
      _verificationErrorText = null;
    });

    final success = await authProvider.requestOTP(normalizedPhone);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingCode = false;
    });

    if (success) {
      setState(() {
        _isOtpSent = true;
        _normalizedPhone = normalizedPhone;
        _verificationErrorText = null;
        _otpController.clear();
      });
      _startResendCountdown();
    } else {
      setState(() {
        if (authProvider.phoneFieldError != null) {
          _phoneErrorText = authProvider.phoneFieldError;
        } else {
          _verificationErrorText = authProvider.error;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isArabic = languageProvider.isArabic;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: widget.onNavigateToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                AnimatedReveal(
                  child: Text(
                    isArabic ? 'إنشاء حساب جديد' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                AnimatedReveal(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    isArabic
                        ? 'انضم إلينا وابدأ رحلة اللياقة'
                        : 'Join us and start your fitness journey',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Full Name
                AnimatedReveal(
                  delay: const Duration(milliseconds: 200),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الاسم الكامل' : 'Full Name',
                      hintText: isArabic ? 'أحمد محمد' : 'John Doe',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isArabic
                            ? 'الرجاء إدخال الاسم'
                            : 'Please enter your name';
                      }
                      if (value.length < 3) {
                        return isArabic
                            ? 'الاسم قصير جداً'
                            : 'Name is too short';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Email
                AnimatedReveal(
                  delay: const Duration(milliseconds: 260),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'البريد الإلكتروني' : 'Email',
                      hintText: 'example@email.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isArabic
                            ? 'الرجاء إدخال البريد'
                            : 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return isArabic ? 'بريد غير صالح' : 'Invalid email';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Phone
                AnimatedReveal(
                  delay: const Duration(milliseconds: 320),
                  child: InternationalPhoneInput(
                    controller: _phoneController,
                    label: isArabic ? 'رقم الهاتف' : 'Phone Number',
                    hint: isArabic ? '10 1234 5678' : '10 1234 5678',
                    selectedCountry: _selectedCountry,
                    onCountryChanged: (country) {
                      setState(() {
                        _selectedCountry = country;
                        _phoneErrorText = null;
                        _resetOtpState();
                      });
                      context.read<AuthProvider>().clearErrors();
                    },
                    onChanged: (_) {
                      setState(() {
                        _phoneErrorText = null;
                        _resetOtpState();
                      });
                      context.read<AuthProvider>().clearErrors();
                    },
                    enabled: !authProvider.isLoading && !_isSendingCode && !_isCreatingAccount,
                    errorText: _phoneErrorText,
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                AnimatedReveal(
                  delay: const Duration(milliseconds: 380),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'كلمة المرور' : 'Password',
                      hintText: isArabic
                          ? '8 أحرف على الأقل'
                          : 'At least 8 characters',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isArabic
                            ? 'الرجاء إدخال كلمة المرور'
                            : 'Please enter password';
                      }
                      if (value.length < 8) {
                        return isArabic
                            ? 'كلمة المرور قصيرة'
                            : 'Password too short';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Password
                AnimatedReveal(
                  delay: const Duration(milliseconds: 440),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                      hintText: isArabic
                          ? 'أعد كتابة كلمة المرور'
                          : 'Re-enter password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isArabic
                            ? 'الرجاء تأكيد كلمة المرور'
                            : 'Please confirm password';
                      }
                      if (value != _passwordController.text) {
                        return isArabic
                            ? 'كلمة المرور غير متطابقة'
                            : 'Passwords don\'t match';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Terms and conditions
                AnimatedReveal(
                  delay: const Duration(milliseconds: 520),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text: isArabic
                                      ? 'أوافق على '
                                      : 'I agree to the ',
                                ),
                                TextSpan(
                                  text: isArabic
                                      ? 'الشروط والأحكام'
                                      : 'Terms & Conditions',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(
                                  text: isArabic ? ' و' : ' and ',
                                ),
                                TextSpan(
                                  text: isArabic
                                      ? 'سياسة الخصوصية'
                                      : 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isOtpSent) ...[
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 560),
                    child: TextFormField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'رمز التحقق' : 'Verification Code',
                        hintText: isArabic ? 'أدخل 6 أرقام' : 'Enter 6 digits',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: _verificationErrorText,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resendEnabled && !_isSendingCode && !_isCreatingAccount
                          ? () => _sendCode(isArabic)
                          : null,
                      child: Text(
                        _resendEnabled
                            ? (isArabic ? 'إعادة الإرسال' : 'Resend code')
                            : '${isArabic ? 'إعادة الإرسال خلال' : 'Resend in'} $_resendCountdown',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Sign up button
                AnimatedReveal(
                  delay: const Duration(milliseconds: 580),
                  child: CustomButton(
                    text: _isSendingCode
                        ? (isArabic ? 'جارٍ إرسال الرمز...' : 'Sending code...')
                        : _isCreatingAccount
                            ? (isArabic ? 'جاري الإنشاء...' : 'Creating account...')
                            : _isOtpSent
                                ? (isArabic ? 'إنشاء حساب' : 'Create Account')
                                : (isArabic ? 'إرسال الرمز' : 'Send Code'),
                    onPressed: authProvider.isLoading || _isSendingCode || _isCreatingAccount
                        ? null
                        : () => _isOtpSent ? _handleSignup(isArabic) : _sendCode(isArabic),
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                  ),
                ),

                const SizedBox(height: 24),

                // Divider with "OR"
                AnimatedReveal(
                  delay: const Duration(milliseconds: 640),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          isArabic ? 'أو' : 'OR',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Social signup buttons
                AnimatedReveal(
                  delay: const Duration(milliseconds: 700),
                  child: Text(
                    isArabic ? 'أو إنشاء حساب باستخدام' : 'Or sign up with',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Social buttons row
                AnimatedReveal(
                  delay: const Duration(milliseconds: 760),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.g_mobiledata,
                          label: 'Google',
                          color: const Color(0xFFDB4437),
                          onPressed: () => _socialSignup('google', isArabic),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: const Color(0xFF4267B2),
                          onPressed: () => _socialSignup('facebook', isArabic),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.apple,
                          label: 'Apple',
                          color: Colors.black,
                          onPressed: () => _socialSignup('apple', isArabic),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Login link
                AnimatedReveal(
                  delay: const Duration(milliseconds: 820),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isArabic
                            ? 'لديك حساب بالفعل؟'
                            : 'Already have an account?',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToLogin,
                        child: Text(
                          isArabic ? 'تسجيل الدخول' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Future<void> _handleSignup(bool isArabic) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'الرجاء الموافقة على الشروط والأحكام'
                : 'Please agree to Terms & Conditions',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final normalizedPhone = _normalizedPhone ?? _validateAndNormalizePhone(isArabic);
    if (normalizedPhone == null) {
      return;
    }

    final otpCode = _otpController.text.trim();
    if (otpCode.length != 6) {
      setState(() {
        _verificationErrorText =
            isArabic ? 'أدخل رمز تحقق مكوناً من 6 أرقام' : 'Enter a 6-digit verification code';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    setState(() {
      _isCreatingAccount = true;
      _verificationErrorText = null;
    });

    final success = await authProvider.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: normalizedPhone,
      password: _passwordController.text,
      otpCode: otpCode,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreatingAccount = false;
    });

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        if (authProvider.phoneFieldError != null) {
          _phoneErrorText = authProvider.phoneFieldError;
        } else {
          _verificationErrorText = authProvider.error;
        }
      });
    }
  }

  Future<void> _socialSignup(String provider, bool isArabic) async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.socialLogin(provider);

    if (success && mounted) {
      widget.onAuthenticated();
    } else if (authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
