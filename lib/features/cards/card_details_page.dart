import 'package:flutter/material.dart';

import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class CardDetailsPage extends StatelessWidget {
  const CardDetailsPage({super.key});

  String get maskedNumber => '••••  ••••  ••••  1234';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PageScaffold(
      appBar: AppBar(
        title: const Text('Card details'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vaulted card',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary
                                .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Virtual Vault • Personal',
                                style: textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                maskedNumber,
                                style: textTheme.titleLarge?.copyWith(
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CARD HOLDER',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Demo User'),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'EXPIRES',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('12/29'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Edit card',
                                icon: Icons.edit_rounded,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Edit flow not implemented'),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Delete not wired (demo only).',
                                      ),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.delete_outline_rounded),
                                label: const Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Security',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'CardVault stores your card details securely. '
                          'This screen is purely a visual demo for your internship project.',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Masked number',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sensitive fields hidden',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

