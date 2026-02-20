import 'package:flutter/material.dart';

import 'package:card_vault/core/models/vault_card.dart';
import 'package:card_vault/core/router/app_router.dart';
import 'package:card_vault/core/services/firestore_card_service.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class CardDetailsPage extends StatelessWidget {
  const CardDetailsPage({super.key, this.cardId});

  final String? cardId;

  @override
  Widget build(BuildContext context) {
    if (cardId == null || cardId!.isEmpty) {
      return PageScaffold(
        appBar: AppBar(title: const Text('Card details')),
        body: const Center(child: Text('No card selected')),
      );
    }

    final firestore = FirestoreCardService();

    return PageScaffold(
      appBar: AppBar(title: const Text('Card details')),
      body: FutureBuilder<VaultCard?>(
        future: firestore.getCard(cardId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final card = snapshot.data;
          if (card == null) {
            return const Center(child: Text('Card not found'));
          }
          return _CardDetailsBody(card: card);
        },
      ),
    );
  }
}

class _CardDetailsBody extends StatelessWidget {
  const _CardDetailsBody({required this.card});

  final VaultCard card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final personName = card.personName?.trim().isNotEmpty == true ? card.personName! : '—';
    final companyName = card.companyName?.trim().isNotEmpty == true ? card.companyName! : '—';
    final phone = card.phoneNumber?.trim().isNotEmpty == true ? card.phoneNumber! : '—';
    final address = card.address?.trim().isNotEmpty == true ? card.address! : '—';

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Card details',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (card.imageURL != null && card.imageURL!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              card.imageURL!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        if (card.imageURL != null && card.imageURL!.isNotEmpty)
                          const SizedBox(height: 16),
                        _DetailRow(label: 'Person name', value: personName),
                        _DetailRow(label: 'Company', value: companyName),
                        _DetailRow(label: 'Phone', value: phone),
                        _DetailRow(label: 'Address', value: address),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Edit card',
                                icon: Icons.edit_rounded,
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.addCard,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete card?'),
                                      content: const Text(
                                        'This card will be removed from your vault.',
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
                                  if (confirm == true && context.mounted) {
                                    await FirestoreCardService().deleteCard(card.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Card deleted')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
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
                        Text('Security', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text(
                          'CardVault stores your card details securely. '
                          'Only you can view and manage your cards.',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Colors.greenAccent),
                            const SizedBox(width: 8),
                            Text('Secure storage', style: textTheme.bodyMedium),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
