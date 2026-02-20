import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:card_vault/core/models/vault_card.dart';
import 'package:card_vault/core/router/app_router.dart';
import 'package:card_vault/core/services/firestore_card_service.dart';
import 'package:card_vault/core/services/storage_card_service.dart';
import 'package:card_vault/core/services/card_ocr_service_stub.dart'
    if (dart.library.io) 'package:card_vault/core/services/card_ocr_service_io.dart' as card_ocr;
import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/capture_card_modal.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _firestoreCardService = FirestoreCardService();
  final _storageCardService = StorageCardService();
  bool _cameraLoading = false;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return PageScaffold(
      body: Stack(
        children: [
          Row(
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
                        child: StreamBuilder<List<VaultCard>>(
                          stream: _firestoreCardService.streamCards(_userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final cards = snapshot.data ?? [];
                            final hasCards = cards.isNotEmpty;

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final isTwoColumn = constraints.maxWidth > 900;
                                return Flex(
                                  direction: isTwoColumn ? Axis.horizontal : Axis.vertical,
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
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: hasCards
                                                  ? ListView.separated(
                                                      itemCount: cards.length,
                                                      separatorBuilder: (_, __) =>
                                                          const SizedBox(height: 12),
                                                      itemBuilder: (context, index) {
                                                        return _CardTile(
                                                          card: cards[index],
                                                          onView: () {
                                                            Navigator.pushNamed(
                                                              context,
                                                              AppRouter.cardDetails,
                                                              arguments: cards[index].id,
                                                            );
                                                          },
                                                          onEdit: () {
                                                            Navigator.pushNamed(
                                                              context,
                                                              AppRouter.cards,
                                                              arguments: cards[index].id,
                                                            );
                                                          },
                                                          onDelete: () => _deleteCard(cards[index].id),
                                                        );
                                                      },
                                                    )
                                                  : _EmptyCardsState(
                                                      onAddCard: () {
                                                        Navigator.pushNamed(
                                                          context,
                                                          AppRouter.cards,
                                                        );
                                                      },
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16, width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: GlassContainer(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Overview',
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                _StatCard(
                                                  label: 'Active cards',
                                                  value: '${cards.length}',
                                                  onTap: () => _showActiveCardsSheet(context, cards),
                                                ),
                                                const SizedBox(width: 12),
                                                _StatCard(
                                                  label: 'Vaults',
                                                  value: '1',
                                                  onTap: () => _showVaultGallerySheet(context, cards),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              'Add new card',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            _AnimatedAddCardButton(
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRouter.cards,
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
          Positioned(
            right: 24,
            bottom: 24,
            child: _CameraFAB(
              isLoading: _cameraLoading,
              onPressed: _captureAndSaveCard,
            ),
          ),
        ],
      ),
    );
  }

  void _showActiveCardsSheet(BuildContext context, List<VaultCard> cards) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Active cards — card details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Text(
                        'No cards yet. Add a card to see details here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: cards.length,
                      itemBuilder: (_, index) {
                        final c = cards[index];
                        final person = c.personName?.trim().isNotEmpty == true ? c.personName! : '—';
                        final company = c.companyName?.trim().isNotEmpty == true ? c.companyName! : '—';
                        final phone = c.phoneNumber?.trim().isNotEmpty == true ? c.phoneNumber! : '—';
                        final address = c.address?.trim().isNotEmpty == true ? c.address! : '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppColors.surfaceSecondary.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text('Card ${index + 1}', style: Theme.of(context).textTheme.titleSmall),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Person: $person', style: Theme.of(context).textTheme.bodySmall),
                                  Text('Company: $company', style: Theme.of(context).textTheme.bodySmall),
                                  Text('Phone: $phone', style: Theme.of(context).textTheme.bodySmall),
                                  Text('Address: $address', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(ctx, AppRouter.cardDetails, arguments: c.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVaultGallerySheet(BuildContext context, List<VaultCard> cards) {
    final cardsWithImage = cards.where((c) => c.imageURL != null && c.imageURL!.isNotEmpty).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Vault — card images',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: cardsWithImage.isEmpty
                  ? Center(
                      child: Text(
                        'No card images yet. Capture or upload a card to see images here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: cardsWithImage.length,
                      itemBuilder: (_, index) {
                        final c = cardsWithImage[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            showDialog(
                              context: context,
                              builder: (dctx) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: InteractiveViewer(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(c.imageURL!, fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              c.imageURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 48),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCard(String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text(
          'This card will be removed from your vault. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _firestoreCardService.deleteCard(cardId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card deleted')),
        );
      }
    }
  }

  Future<void> _captureAndSaveCard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bytes = await CaptureCardModal.show(context);
    if (bytes == null || !mounted) return;

    setState(() => _cameraLoading = true);
    try {
      // Extract text from card image (OCR on mobile; null on web)
      final extracted = await card_ocr.extractCardTextFromImage(bytes);

      final card = VaultCard(
        id: '',
        userId: user.uid,
        companyName: extracted?.companyName ?? '',
        personName: extracted?.personName ?? '',
        designation: '',
        phoneNumber: extracted?.phoneNumber ?? '',
        email: extracted?.email ?? '',
        website: '',
        address: extracted?.address ?? '',
        notes: '',
        imageURL: '',
      );
      final docId = await _firestoreCardService.addCard(card);

      final url = await _storageCardService.uploadCardImage(
        userId: user.uid,
        cardId: docId,
        bytes: bytes,
      );

      await _firestoreCardService.updateCard(
        card.copyWith(id: docId, imageURL: url),
      );

      if (mounted) {
        setState(() => _cameraLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              extracted != null
                  ? 'Card saved with extracted details. View in Active cards or Cards page.'
                  : 'Card image saved. Add details on the Cards page.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamed(context, AppRouter.cards);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
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
            onTap: () {
              Navigator.pushNamed(context, AppRouter.cards);
            },
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
            'CardVault',
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

String _greetingByTime() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 22) return 'Good evening';
  return 'Good night';
}

class _Header extends StatelessWidget {
  const _Header({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final greetingName = displayName != null && displayName.isNotEmpty
        ? displayName
        : 'there';
    final greeting = _greetingByTime();

    return Row(
      mainAxisAlignment:
          isWide ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $greetingName 👋',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is an overview of your secure vault.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        if (isWide)
          PrimaryButton(
            label: 'Add new card',
            icon: Icons.add_rounded,
            isExpanded: false,
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.cards);
            },
          ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final VaultCard card;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final personName = card.personName?.trim().isNotEmpty == true
        ? card.personName!
        : 'No name';
    final companyName = card.companyName?.trim().isNotEmpty == true
        ? card.companyName!
        : 'No company';
    final phone = card.phoneNumber?.trim().isNotEmpty == true
        ? card.phoneNumber!
        : '—';

    return Material(
      color: AppColors.surfaceSecondary.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (card.imageURL != null && card.imageURL!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    card.imageURL!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 52, height: 52),
                  ),
                ),
              if (card.imageURL != null && card.imageURL!.isNotEmpty) const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      personName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyName,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'view') onView();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('View'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outlined, size: 20, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState({required this.onAddCard});

  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: child,
                    ),
                  );
                },
                child: const Icon(
                  Icons.credit_card_off_rounded,
                  size: 80,
                  color: Colors.white24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No cards added yet.',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click below to add your first card.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Add your first card',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.accentIndigo,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Add your first card',
                icon: Icons.add_rounded,
                onPressed: onAddCard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
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
    );
    return Expanded(
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: content,
              ),
            )
          : content,
    );
  }
}

class _AnimatedAddCardButton extends StatefulWidget {
  const _AnimatedAddCardButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AnimatedAddCardButton> createState() => _AnimatedAddCardButtonState();
}

class _AnimatedAddCardButtonState extends State<_AnimatedAddCardButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: PrimaryButton(
        label: 'Add new card',
        icon: Icons.add_rounded,
        onPressed: widget.onPressed,
      ),
    );
  }
}

class _CameraFAB extends StatelessWidget {
  const _CameraFAB({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: AppColors.accentIndigo,
      icon: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.camera_alt_rounded),
      label: Text(isLoading ? 'Saving...' : 'Capture card'),
    );
  }
}
