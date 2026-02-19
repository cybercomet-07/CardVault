import 'package:flutter/material.dart';

import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return PageScaffold(
      appBar: AppBar(
        title: const Text('Add card'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSideBySide = constraints.maxWidth > 900;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Flex(
                  direction:
                      showSideBySide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Card details',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _holderController,
                                decoration: const InputDecoration(
                                  labelText: 'Card holder name',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _numberController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Card number',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _expiryController,
                                      decoration: const InputDecoration(
                                        labelText: 'Expiry (MM/YY)',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cvvController,
                                      decoration: const InputDecoration(
                                        labelText: 'CVV',
                                      ),
                                      obscureText: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: 'Save card (demo)',
                                icon: Icons.check_rounded,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Card saved in UI only (no backend).',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16, width: 16),
                    Expanded(
                      flex: 2,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _CardPreview(
                          key: ValueKey(_numberController.text +
                              _holderController.text +
                              _expiryController.text),
                          holder: _holderController.text,
                          number: _numberController.text,
                          expiry: _expiryController.text,
                          isWide: isWide,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    super.key,
    required this.holder,
    required this.number,
    required this.expiry,
    required this.isWide,
  });

  final String holder;
  final String number;
  final String expiry;
  final bool isWide;

  String get _displayNumber {
    if (number.isEmpty) return '••••  ••••  ••••  ••••';
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final padded = digits.padRight(16, '•');
    final chunks =
        Iterable.generate(4, (i) => padded.substring(i * 4, (i + 1) * 4))
            .join('  ');
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: isWide ? Alignment.centerRight : Alignment.center,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                AppColors.accentIndigo,
                AppColors.accentPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                  ),
                  Text(
                    'CARDVAULT',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _displayNumber,
                style: textTheme.titleLarge?.copyWith(
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARD HOLDER',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        holder.isEmpty ? 'Your name' : holder,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPIRES',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expiry.isEmpty ? 'MM/YY' : expiry,
                        style: textTheme.bodyMedium,
                      ),
                    ],
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

