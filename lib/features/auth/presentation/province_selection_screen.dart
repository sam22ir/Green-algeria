import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';

class ProvinceSelectionScreen extends StatefulWidget {
  const ProvinceSelectionScreen({super.key});

  @override
  State<ProvinceSelectionScreen> createState() => _ProvinceSelectionScreenState();
}

class _ProvinceSelectionScreenState extends State<ProvinceSelectionScreen> {
  int? _selectedProvinceId;
  List<Map<String, dynamic>> _provinces = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
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

  Future<void> _saveProvince() async {
    if (_selectedProvinceId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Update users table
        await Supabase.instance.client.from('users').update({
          'province_id': _selectedProvinceId,
        }).eq('id', user.id);

        // ✅ Force-sync AuthService so hasProvince updates before navigation
        final authService = AuthService();
        await authService.syncCurrentUser();

        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('save_error'.tr()), 
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Nature Background (Top 45% focus)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
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
          
          // Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.4, 0.9, 1.0],
                ),
              ),
            ),
          ),

          // 2. Centered Branding Title
          Positioned(
            top: size.height * 0.10,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
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
                  'app_name'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 3. Content
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.60,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'select_province_title'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'select_province_desc'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),

                      Align(
                        alignment: context.locale.languageCode == 'ar' ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text(
                            'province'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<int>(
                            value: _selectedProvinceId,
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                            dropdownColor: colorScheme.surface,
                            hint: Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  'province_hint'.tr(),
                                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 14),
                                ),
                              ],
                            ),
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
                            items: _provinces.map((p) {
                              return DropdownMenuItem<int>(
                                value: p['id'] as int,
                                child: Text(
                                  context.locale.languageCode == 'ar' ? p['name_ar'] : p['name_en'],
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() => _selectedProvinceId = newValue);
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'location_usage_info'.tr(),
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      ElevatedButton(
                        onPressed: (_selectedProvinceId == null || _isLoading) ? null : _saveProvince,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 58),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                        child: _isLoading 
                          ? CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2.5)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'confirm'.tr(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
          
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
