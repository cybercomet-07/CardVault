import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:card_vault/core/models/user_profile.dart';
import 'package:card_vault/core/router/app_router.dart';
import 'package:card_vault/core/services/storage_card_service.dart';
import 'package:card_vault/core/services/user_profile_service.dart';
import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _userProfileService = UserProfileService();
  final _storageService = StorageCardService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  bool _saving = false;
  String? _photoUrl;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await _userProfileService.getProfile(user.uid);
    final resolved = profile ??
        UserProfile(
          uid: user.uid,
          fullName: user.displayName,
          email: user.email,
          photoUrl: user.photoURL,
          themeMode: 'dark',
        );
    _profile = resolved;
    _nameController.text = resolved.fullName ?? '';
    _phoneController.text = resolved.phone ?? '';
    _companyController.text = resolved.company ?? '';
    _photoUrl = resolved.photoUrl ?? user.photoURL;
    if (mounted) setState(() {});
  }

  Future<void> _pickProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 88,
      );
      if (picked == null) return;
      setState(() => _saving = true);
      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadProfileImage(
        userId: user.uid,
        bytes: bytes,
      );
      await user.updatePhotoURL(url);
      _photoUrl = url;
      await _userProfileService.upsertProfile(
        (_profile ?? UserProfile(uid: user.uid)).copyWith(photoUrl: url),
      );
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final fullName = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final company = _companyController.text.trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }
      await _userProfileService.upsertProfile(
        UserProfile(
          uid: user.uid,
          fullName: fullName,
          email: user.email,
          phone: phone,
          company: company,
          photoUrl: _photoUrl ?? user.photoURL,
          themeMode: 'dark',
        ),
      );
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? Colors.white70
        : colorScheme.onSurface.withValues(alpha: 0.72);
    final fieldFill = isDark
        ? AppColors.surfaceSecondary.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.96);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final email = user?.email ?? '';

    return PageScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Settings',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 12),
                    const _MobileSectionNav(currentRoute: AppRouter.settings),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _saving ? null : _pickProfilePhoto,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppColors.accentIndigo.withValues(alpha: 0.6),
                          backgroundImage:
                              (_photoUrl != null && _photoUrl!.isNotEmpty)
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                          child: (_photoUrl == null || _photoUrl!.isEmpty)
                              ? const Icon(Icons.person_rounded)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName != null && displayName.isNotEmpty
                                ? displayName
                                : 'User',
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            email.isNotEmpty ? email : 'Not signed in',
                            style:
                                textTheme.bodySmall?.copyWith(color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      filled: true,
                      fillColor: fieldFill,
                      labelStyle: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      filled: true,
                      fillColor: fieldFill,
                      labelStyle: TextStyle(color: secondaryTextColor),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _companyController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Company',
                      filled: true,
                      fillColor: fieldFill,
                      labelStyle: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: _saving ? 'Saving...' : 'Save profile',
                    icon: _saving ? null : Icons.save_rounded,
                    onPressed: _saving ? null : _saveProfile,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Back to dashboard',
                    icon: Icons.dashboard_rounded,
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
                    },
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Log out',
                    icon: Icons.logout_rounded,
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRouter.login,
                          (route) => false,
                        );
                      }
                    },
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSectionNav extends StatelessWidget {
  const _MobileSectionNav({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _MobileSectionNavItem(
              label: 'Dashboard',
              icon: Icons.dashboard_rounded,
              isActive: currentRoute == AppRouter.dashboard,
              onTap: () => _go(context, AppRouter.dashboard),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MobileSectionNavItem(
              label: 'Cards',
              icon: Icons.credit_card_rounded,
              isActive: currentRoute == AppRouter.cards,
              onTap: () => _go(context, AppRouter.cards),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MobileSectionNavItem(
              label: 'Settings',
              icon: Icons.settings_rounded,
              isActive: currentRoute == AppRouter.settings,
              onTap: () => _go(context, AppRouter.settings),
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }
}

class _MobileSectionNavItem extends StatelessWidget {
  const _MobileSectionNavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? Colors.white : Colors.white70;
    return Material(
      color: isActive
          ? AppColors.accentIndigo.withValues(alpha: 0.9)
          : AppColors.surfaceSecondary.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

