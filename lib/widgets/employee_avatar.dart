import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/theme/app_theme.dart';

class EmployeeAvatar extends StatelessWidget {
  final UserModel? user;
  final String? name;
  final double radius;

  const EmployeeAvatar({
    super.key,
    this.user,
    this.name,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name ?? name ?? '?';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryLight,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
