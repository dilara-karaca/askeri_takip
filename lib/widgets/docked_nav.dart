import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmergencyFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final double size;

  const EmergencyFab({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = AppColors.emergency,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A120E).withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: color,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
