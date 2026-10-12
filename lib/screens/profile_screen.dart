import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/recipe_repository.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}
    final isGuest = user == null || user.isAnonymous;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final repo = Provider.of<RecipeRepository>(context);

    final displayName = user?.displayName ?? (isGuest ? "Guest Chef" : "Chef");
    final displayEmail = user?.email ?? (isGuest ? "Running in Offline / Guest Mode" : "No email");

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text("Chef Profile 👨‍🍳"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // User Card Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : "🍳",
                            style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 14),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                    ),
                    if (isGuest) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondaryAmber.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, color: AppColors.secondaryAmber, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Guest Mode • Data saved locally",
                              style: TextStyle(
                                color: AppColors.secondaryAmber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Activity Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Saved Recipes",
                      value: "${repo.savedCount}",
                      icon: Icons.bookmark_added,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "AI Generated",
                      value: "${repo.generatedCount}",
                      icon: Icons.auto_awesome,
                      color: AppColors.secondaryAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Settings Section
              Material(
                color: AppColors.surface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.border(context)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        "Dark Mode",
                        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        themeProvider.isDarkMode ? "Enabled (Night Kitchen)" : "Disabled (Daylight)",
                        style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => themeProvider.toggleTheme(),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.border(context)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sync, color: Colors.blueAccent),
                      ),
                      title: Text(
                        "Sync Cloud Library",
                        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Update recipes from Cloud Firestore",
                        style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final success = await repo.syncFromFirestore();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? "Cloud sync completed! ✨"
                                    : "Could not sync recipes right now. Please check your internet connection.",
                              ),
                              backgroundColor: success ? AppColors.primary : Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    Divider(height: 1, color: AppColors.border(context)),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.green),
                      ),
                      title: Text(
                        "Default Diet Preference",
                        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "No Restrictions",
                        style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      if (Firebase.apps.isNotEmpty) {
                        await FirebaseAuth.instance.signOut();
                      }
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  label: Text(
                    isGuest ? "Exit Guest Mode" : "Sign Out",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                "CookSmart AI • v1.0.5 (Release Build)",
                style: TextStyle(color: AppColors.muted(context), fontSize: 11),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
