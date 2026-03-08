import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_buttons.dart';
import '../../../core/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _registerWithEmail() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw 'الرجاء إدخال جميع البيانات المطلوبة';
      }

      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'role': 'volunteer', // Default role for new signups
        }
      );
      
      if (res.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التسجيل بنجاح! الرجاء تأكيد بريدك الإلكتروني.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إنشاء حساب جديد',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mossForest,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'انضم إلينا في مهمة تشجير الجزائر',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.oliveGrey,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'الاسم الكامل',
                hint: 'محمد أمين',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'البريد الإلكتروني',
                hint: 'example@email.com',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'كلمة المرور',
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                isPassword: _obscurePassword,
                controller: _passwordController,
                suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
                onSuffixIconPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'إنشاء حساب',
                onPressed: _registerWithEmail,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
