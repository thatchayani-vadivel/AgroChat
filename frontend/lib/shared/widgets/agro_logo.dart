import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';

/// Reusable AgroChat emblem used across splash, auth, and header views.
class AgroLogo extends StatelessWidget {
  const AgroLogo({super.key, this.size = 72, this.showTitle = true});

  final double size;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryGreenLight,
                AppColors.primaryGreen,
                AppColors.primaryGreenDark,
              ],
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: size * 0.54,
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 14),
          Text(
            'AgroChat',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: AppColors.primaryGreenDark),
          ),
        ],
      ],
    );
  }
}
