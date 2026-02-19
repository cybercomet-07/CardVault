import 'package:flutter/material.dart';

import 'package:card_vault/core/router/app_router.dart';
import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return PageScaffold(
      body: Row(
        children: [
          if (isWide) const _Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(isWide: isWide),
                  const SizedBox(height: 24),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isTwoColumn = constraints.maxWidth > 900;
                        return Flex(
                          direction:
                              isTwoColumn ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: GlassContainer(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your cards',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: 4,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRouter.cardDetails,
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            tileColor: AppColors
                                                .surfaceSecondary
                                                .withValues(alpha: 0.7),
                                            leading: const Icon(
                                              Icons.credit_card_rounded,
                                            ),
                                            title: Text('Demo card ${index + 1}'),
                                            subtitle: const Text(
                                              '•••• •••• •••• 1234',
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right_rounded,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              flex: 1,
                              child: GlassContainer(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overview',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        _StatCard(
                                          label: 'Active cards',
                                          value: '4',
                                        ),
                                        const SizedBox(width: 12),
                                        _StatCard(
                                          label: 'Vaults',
                                          value: '1',
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    PrimaryButton(
                                      label: 'Add card',
                                      icon: Icons.add_rounded,
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRouter.addCard,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_moon_rounded),
              const SizedBox(width: 8),
              Text(
                'CardVault',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isActive: true,
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.credit_card_rounded,
            label: 'Cards',
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              Navigator.pushNamed(context, AppRouter.settings);
            },
          ),
          const Spacer(),
          Text(
            'Internship demo build',
            style: textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.accentIndigo
        : Colors.white.withValues(alpha: 0.8);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment:
          isWide ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good afternoon, Intern 👋',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is an overview of your secure vault.',
              style:
                  textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        if (isWide)
          PrimaryButton(
            label: 'Add card',
            icon: Icons.add_rounded,
            isExpanded: false,
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.addCard);
            },
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

