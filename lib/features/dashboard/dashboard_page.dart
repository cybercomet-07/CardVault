import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:card_vault/core/models/vault_card.dart';
import 'package:card_vault/core/router/app_router.dart';
import 'package:card_vault/core/services/firestore_card_service.dart';
import 'package:card_vault/core/services/storage_card_service.dart';
import 'package:card_vault/core/services/card_ocr_service_stub.dart'
    if (dart.library.io) 'package:card_vault/core/services/card_ocr_service_io.dart'
    if (dart.library.html) 'package:card_vault/core/services/card_ocr_service_web.dart' as card_ocr;
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
                      if (!isWide) ...[
                        const SizedBox(height: 14),
                        const _MobileSectionNav(currentRoute: AppRouter.dashboard),
                      ],
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
                                if (isTwoColumn) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _CardsPanel(
                                          cards: cards,
                                          hasCards: hasCards,
                                          onAddCard: () {
                                            Navigator.pushNamed(context, AppRouter.cards);
                                          },
                                          onViewCard: (id) {
                                            Navigator.pushNamed(
                                              context,
                                              AppRouter.cardDetails,
                                              arguments: id,
                                            );
                                          },
                                          onEditCard: (id) {
                                            Navigator.pushNamed(
                                              context,
                                              AppRouter.cards,
                                              arguments: id,
                                            );
                                          },
                                          onDeleteCard: _deleteCard,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: _OverviewPanel(
                                          cards: cards,
                                          cameraLoading: _cameraLoading,
                                          onCapture: _captureAndSaveCard,
                                          onOpenActive: () => _showActiveCardsSheet(context, cards),
                                          onOpenVault: () => _showVaultGallerySheet(context, cards),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _CardsPanel(
                                        cards: cards,
                                        hasCards: hasCards,
                                        maxHeight: 420,
                                        onAddCard: () {
                                          Navigator.pushNamed(context, AppRouter.cards);
                                        },
                                        onViewCard: (id) {
                                          Navigator.pushNamed(
                                            context,
                                            AppRouter.cardDetails,
                                            arguments: id,
                                          );
                                        },
                                        onEditCard: (id) {
                                          Navigator.pushNamed(
                                            context,
                                            AppRouter.cards,
                                            arguments: id,
                                          );
                                        },
                                        onDeleteCard: _deleteCard,
                                      ),
                                      const SizedBox(height: 16),
                                      _OverviewPanel(
                                        cards: cards,
                                        cameraLoading: _cameraLoading,
                                        onCapture: _captureAndSaveCard,
                                        onOpenActive: () => _showActiveCardsSheet(context, cards),
                                        onOpenVault: () => _showVaultGallerySheet(context, cards),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
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
                        final businessType = c.businessType?.trim().isNotEmpty == true ? c.businessType! : '—';
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
                                  Text('Business type: $businessType', style: Theme.of(context).textTheme.bodySmall),
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
    String? docId;
    try {
      // Extract text from card image (OCR on mobile; null on web)
      final extracted = await card_ocr.extractCardTextFromImage(bytes);

      final card = VaultCard(
        id: '',
        userId: user.uid,
        companyName: extracted?.companyName ?? '',
        personName: extracted?.personName ?? '',
        businessType: extracted?.businessType ?? 'Other',
        designation: '',
        phoneNumber: extracted?.phoneNumber ?? '',
        email: extracted?.email ?? '',
        website: extracted?.website ?? '',
        address: extracted?.address ?? '',
        notes: '',
        imageURL: '',
      );
      docId = await _firestoreCardService.addCard(card);
      final cardWithId = card.copyWith(id: docId);

      // Upload image with timeout so we never hang (e.g. web Storage CORS)
      String? url;
      try {
        url = await _storageCardService
            .uploadCardImage(userId: user.uid, cardId: docId, bytes: bytes)
            .timeout(const Duration(seconds: 25));
        await _firestoreCardService.updateCard(
          cardWithId.copyWith(imageURL: url),
        );
      } catch (_) {
        // Card already saved; image upload failed or timed out
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Card saved. Image upload failed — add details and image on the Cards page.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (mounted) {
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                extracted != null
                    ? 'Card saved with extracted details. View in Active cards or Cards page.'
                    : 'Card saved. Add name, company, etc. on the Cards page.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        Navigator.pushNamed(context, AppRouter.cards, arguments: docId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save card: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _cameraLoading = false);
    }
  }
}

class _CardsPanel extends StatelessWidget {
  const _CardsPanel({
    required this.cards,
    required this.hasCards,
    required this.onAddCard,
    required this.onViewCard,
    required this.onEditCard,
    required this.onDeleteCard,
    this.maxHeight,
  });

  final List<VaultCard> cards;
  final bool hasCards;
  final VoidCallback onAddCard;
  final void Function(String id) onViewCard;
  final void Function(String id) onEditCard;
  final void Function(String id) onDeleteCard;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final content = GlassContainer(
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return _CardTile(
                        card: card,
                        onView: () => onViewCard(card.id),
                        onEdit: () => onEditCard(card.id),
                        onDelete: () => onDeleteCard(card.id),
                      );
                    },
                  )
                : _EmptyCardsState(onAddCard: onAddCard),
          ),
        ],
      ),
    );
    if (maxHeight == null) return content;
    return SizedBox(height: maxHeight, child: content);
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.cards,
    required this.cameraLoading,
    required this.onCapture,
    required this.onOpenActive,
    required this.onOpenVault,
  });

  final List<VaultCard> cards;
  final bool cameraLoading;
  final VoidCallback onCapture;
  final VoidCallback onOpenActive;
  final VoidCallback onOpenVault;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
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
                onTap: onOpenActive,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Vaults',
                value: '1',
                onTap: onOpenVault,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 340,
            child: _BusinessTypeChart(
              cards: cards,
              cameraLoading: cameraLoading,
              onCapture: onCapture,
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

/// Standard business types for cards.
const List<String> _businessTypes = [
  'Technology',
  'Healthcare',
  'Finance',
  'Marketing',
  'Retail',
  'Education',
  'Other',
];

class _BusinessTypeChart extends StatefulWidget {
  const _BusinessTypeChart({
    required this.cards,
    required this.cameraLoading,
    required this.onCapture,
  });

  final List<VaultCard> cards;
  final bool cameraLoading;
  final VoidCallback onCapture;

  @override
  State<_BusinessTypeChart> createState() => _BusinessTypeChartState();
}

class _BusinessTypeChartState extends State<_BusinessTypeChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final t in _businessTypes) {
      counts[t] = 0;
    }
    for (final c in widget.cards) {
      final t = (c.businessType ?? '').trim();
      final key = t.isEmpty ? 'Other' : (_businessTypes.contains(t) ? t : 'Other');
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final total = widget.cards.length;
    final colorByType = <String, Color>{
      'Technology': AppColors.accentIndigo,
      'Healthcare': Colors.tealAccent,
      'Finance': Colors.amberAccent,
      'Marketing': Colors.pinkAccent,
      'Retail': Colors.cyanAccent,
      'Education': Colors.lightGreenAccent,
      'Other': AppColors.accentPurple,
    };

    if (total == 0) {
      return Center(
        child: Text(
          'Add cards to see business type breakdown',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
        ),
      );
    }
    final sections = <PieChartSectionData>[];
    for (final t in _businessTypes) {
      final n = counts[t] ?? 0;
      if (n > 0) {
        sections.add(
          PieChartSectionData(
            value: n.toDouble(),
            title: '$n',
            color: colorByType[t] ?? Colors.white70,
            radius: 36,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    if (sections.isEmpty) {
      return Center(
        child: Text(
          'Add cards with business type to see chart',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
        ),
      );
    }

    final topType = counts.entries
        .where((e) => e.value > 0)
        .fold<MapEntry<String, int>?>(null, (best, cur) {
      if (best == null) return cur;
      return cur.value > best.value ? cur : best;
    });
    final usedTypes = counts.entries.where((e) => e.value > 0).length;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: sections
                              .map((s) => PieChartSectionData(
                                    value: s.value,
                                    title: s.title,
                                    color: s.color,
                                    radius: s.radius * _animation.value,
                                    titleStyle: s.titleStyle,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _businessTypes
                            .where((t) => (counts[t] ?? 0) > 0)
                            .map((t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colorByType[t] ?? Colors.white70,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          t,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insights',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Top type: ${topType?.key ?? '—'} (${topType?.value ?? 0})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Types used: $usedTypes / ${_businessTypes.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total cards: $total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _CameraFAB(
                          isLoading: widget.cameraLoading,
                          onPressed: widget.onCapture,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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
