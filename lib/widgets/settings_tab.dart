import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme.dart';

class SettingsTab extends StatelessWidget {
  final UserProfile? myProfile;
  final VoidCallback onLogout;

  const SettingsTab({
    super.key,
    required this.myProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Réglages",
          style: AppText.heading(fontSize: 24),
        ),
        const SizedBox(height: 24),
        if (myProfile != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppCard.decoration(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.card),
                    child: ClipOval(
                      child: myProfile!.avatarUrl != null
                          ? Image.network(
                              myProfile!.avatarUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        myProfile!.displayName,
                        style: AppText.heading(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        myProfile!.email,
                        style: AppText.body(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Container(
          decoration: AppCard.decoration(),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.danger, size: 20),
                ),
                title: Text(
                  "Déconnexion",
                  style: AppText.body(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "Se déconnecter de votre compte 42",
                  style: AppText.body(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                trailing: const Icon(Icons.keyboard_arrow_right_rounded,
                    color: AppColors.mutedLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Text(
                "Little 42 Companion",
                style: AppText.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Version 1.0.0",
                style: AppText.body(
                  fontSize: 12,
                  color: AppColors.mutedLight.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.primarySoft,
      child: const Icon(Icons.person, size: 28, color: AppColors.primary),
    );
  }
}