import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/animated_reveal.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                        return isArabic ? 'الرجاء إدخال الاسم' : 'Please enter your name';
                      }
                      if (value.length < 3) {
                        return isArabic ? 'الاسم قصير جداً' : 'Name is too short';
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
                        return isArabic ? 'الرجاء إدخال البريد' : 'Please enter email';
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
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'رقم الهاتف' : 'Phone Number',
                      hintText: '+966 5X XXX XXXX',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isArabic ? 'الرجاء إدخال رقم الهاتف' : 'Please enter phone';
                      }
                      return null;
                    },
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
                      hintText: isArabic ? '8 أحرف على الأقل' : 'At least 8 characters',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                        return isArabic ? 'الرجاء إدخال كلمة المرور' : 'Please enter password';
                      }
                      if (value.length < 8) {
                        return isArabic ? 'كلمة المرور قصيرة' : 'Password too short';
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
                      labelText: isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                      hintText: isArabic ? 'أعد كتابة كلمة المرور' : 'Re-enter password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
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
                        return isArabic ? 'الرجاء تأكيد كلمة المرور' : 'Please confirm password';
                      }
                      if (value != _passwordController.text) {
                        return isArabic ? 'كلمة المرور غير متطابقة' : 'Passwords don\'t match';
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
                
                const SizedBox(height: 24),
                
                // Sign up button
                AnimatedReveal(
                  delay: const Duration(milliseconds: 580),
                  child: CustomButton(
                    text: authProvider.isLoading
                        ? (isArabic ? 'جاري الإنشاء...' : 'Creating account...')
                        : (isArabic ? 'إنشاء حساب' : 'Sign Up'),
                    onPressed: authProvider.isLoading ? null : () => _handleSignup(isArabic),
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
                        isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?',
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
    
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    
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
