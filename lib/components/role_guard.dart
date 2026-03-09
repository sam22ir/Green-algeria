import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const SizedBox.shrink(); // Could show a loading spinner
        }
        
        final userModel = authService.currentUserModel;
        if (userModel != null && allowedRoles.contains(userModel.role)) {
          return child;
        }

        return fallback;
      },
    );
  }
}
