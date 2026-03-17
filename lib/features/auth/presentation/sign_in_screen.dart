import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // AppRouter will automatically handle redirecting to / or /select-province
      // based on whether the user has a province_id after _authService finishes loading.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth_error'.tr(args: [e.toString()])), 
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (_isLoading) return; 
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('fill_required_fields'.tr()), 
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.loginWithEmail(email, password);
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'auth_error'.tr(args: [e.message]);
        if (e.statusCode == '429') {
          errorMessage = 'too_many_requests'.tr();
        } else if (e.message.contains('Invalid login')) {
          errorMessage = 'invalid_credentials'.tr();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), 
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Email not confirmed')) {
          _showEmailConfirmationDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth_error'.tr(args: [e.toString()])), 
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailConfirmationDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'confirm_email_title'.tr(), 
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'confirm_email_msg'.tr(),
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('cancel'.tr(), style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.resend(
                  type: OtpType.signup,
                  email: _emailController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('resend_success'.tr()), 
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('resend_error'.tr()), 
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'resend'.tr(), 
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;



    return Scaffold(
      body: Stack(
        children: [
          // 1. Immersive Nature Background
          Positioned.fill(
            child: Hero(
              tag: 'auth_bg',
              child: Image.asset(
                'assets/images/forest_bg_signin.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.primary,
                  child: Center(
                    child: Icon(
                      Icons.forest_rounded,
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      size: 100,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // App Branding
                  _buildBranding(),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome Header
                  _buildHeader(),
                  
                  const SizedBox(height: 50),

                  // Glassmorphism Login Form
                  _buildGlassForm(colorScheme),

                  const SizedBox(height: 40),

                  // Social Auth Section
                  _buildSocialAuth(colorScheme),

                  const SizedBox(height: 30),

                  // Footer Link
                  _buildFooter(colorScheme),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const CircularProgressIndicator(color: Colors.white),
                ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 65,
                height: 65,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'app_name'.tr().toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'welcome_back'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'sign_in_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassForm(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPremiumTextField(
            controller: _emailController,
            hint: 'email'.tr(),
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildPremiumTextField(
            controller: _passwordController,
            hint: 'password'.tr(),
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'forgot_password'.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _signInWithEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            ),
            child: Text(
              'sign_in'.tr(), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.white70, size: 22),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white38, width: 2),
        ),
      ),
    );
  }

  Widget _buildSocialAuth(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or'.tr(),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 30),
          ),
          label: Text(
            'continue_google'.tr(), 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "no_account".tr(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: Text(
            'sign_up'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
