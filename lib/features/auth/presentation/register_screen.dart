import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';
import '../../../constants/avatars.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int? _selectedProvinceId;
  List<Map<String, dynamic>> _provinces = [];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      final data = await Supabase.instance.client
          .from('provinces')
          .select()
          .order('code', ascending: true);
      if (mounted) {
        setState(() {
          _provinces = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    }
  }

  Future<void> _signUp() async {
    if (_isLoading) return; 
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedProvinceId == null) {
      _showErrorSnackbar('province_required'.tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final randomAvatar = AppAvatars.getRandom();

      await _authService.registerWithEmail(
        fullName: name,
        email: email,
        password: password,
        provinceId: _selectedProvinceId,
        avatarAsset: randomAvatar,
      );

      // Note: The users table record is created automatically by AuthService sync listener.
      // But we can still navigate safely since registerWithEmail waits for auth.signUp success.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('success'.tr()), 
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.go('/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('auth_error'.tr(args: [e.toString()]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Theme.of(context).colorScheme.error,
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
          // 1. Nature Background
          Positioned.fill(
            child: Hero(
              tag: 'auth_bg',
              child: Image.asset(
                'assets/images/forest_bg_register.png',
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
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),

          // 2. Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildBranding(),
                    const SizedBox(height: 30),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildGlassForm(colorScheme),
                    const SizedBox(height: 30),
                    _buildFooter(colorScheme),
                    const SizedBox(height: 40),
                  ],
                ),
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
          width: 90,
          height: 90,
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
                width: 55,
                height: 55,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'app_name'.tr().toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
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
          'sign_up'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'be_part_of_change'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassForm(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
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
            controller: _nameController,
            hint: 'full_name'.tr(),
            icon: Icons.person_outline_rounded,
            validator: (val) => val == null || val.isEmpty ? 'field_required'.tr() : null,
          ),
          const SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _emailController,
            hint: 'email'.tr(),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val == null || !val.contains('@') ? 'invalid_email'.tr() : null,
          ),
          const SizedBox(height: 16),
          _buildProvincePicker(colorScheme),
          const SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _passwordController,
            hint: 'password'.tr(),
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            isObscure: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (val) => val != null && val.length < 6 ? 'password_short'.tr() : null,
          ),
          const SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _confirmPasswordController,
            hint: 'confirm_password'.tr(),
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            isObscure: _obscureConfirmPassword,
            onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (val) => val != _passwordController.text ? 'passwords_mismatch'.tr() : null,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            ),
            child: Text(
              'create_account_button'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isObscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white60, size: 20),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white60, size: 18),
          onPressed: onToggleVisibility,
        ) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white38, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildProvincePicker(ColorScheme colorScheme) {
    final selectedProvince = _provinces.cast<Map<String, dynamic>?>().firstWhere(
      (p) => p?['id'] == _selectedProvinceId,
      orElse: () => null,
    );
    final provinceName = selectedProvince != null
        ? (context.locale.languageCode == 'ar' ? selectedProvince['name_ar'] : selectedProvince['name_en'])
        : 'province_hint'.tr();

    return InkWell(
      onTap: () => _showProvincePicker(colorScheme),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.white60, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provinceName,
                style: TextStyle(
                  color: selectedProvince != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  void _showProvincePicker(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'province_hint'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _provinces.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final p = _provinces[index];
                    final pName = context.locale.languageCode == 'ar' ? p['name_ar'] : p['name_en'];
                    final isSelected = _selectedProvinceId == p['id'];
                    return ListTile(
                      title: Text(
                        '${p['code']} - $pName',
                        style: TextStyle(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
                      onTap: () {
                        setState(() => _selectedProvinceId = p['id'] as int);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'have_account'.tr(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'sign_in'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
