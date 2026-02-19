import 'package:flutter/material.dart';

import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PageScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppColors.accentIndigo.withValues(alpha: 0.6),
                        child: const Icon(Icons.person_rounded),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo User',
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            'intern@cardvault.dev',
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.dark_mode_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme',
                              style: textTheme.bodyMedium,
                            ),
                            Text(
                              'Dark / Light toggle (UI only)',
                              style: textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: true,
                        onChanged: (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Theme toggle is visual only in this demo.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
                    label: 'Logout (demo)',
                    icon: Icons.logout_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Logout not wired (demo only).'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

