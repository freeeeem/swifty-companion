import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import 'profile_card.dart';

class ProfileTab extends StatelessWidget {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const ProfileTab({
    super.key,
    required this.profile,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 120.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.cardElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.muted,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Une erreur est survenue",
              style: AppText.heading(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: AppText.body(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }

    if (profile != null) {
      return ProfileCard(profile: profile!);
    }

    return const SizedBox.shrink();
  }
}
