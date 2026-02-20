import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:card_vault/core/models/vault_card.dart';
import 'package:card_vault/core/services/firestore_card_service.dart';
import 'package:card_vault/core/services/storage_card_service.dart';
import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key, this.cardId});

  /// If set, load this card and update on save; otherwise add new.
  final String? cardId;

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _personController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _firestoreCardService = FirestoreCardService();
  final _storageCardService = StorageCardService();

  bool _isLoading = false;
  bool _isEdit = false;
  Uint8List? _imageBytes;
  String? _existingImageURL;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.cardId != null && widget.cardId!.isNotEmpty) {
      _isEdit = true;
      _loadCard();
    }
  }

  Future<void> _loadCard() async {
    final id = widget.cardId!;
    final card = await _firestoreCardService.getCard(id);
    if (card != null && mounted) {
      _companyController.text = card.companyName ?? '';
      _personController.text = card.personName ?? '';
      _phoneController.text = card.phoneNumber ?? '';
      _addressController.text = card.address ?? '';
      _existingImageURL = card.imageURL;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _personController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final company = _companyController.text.trim();
      final person = _personController.text.trim();
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();

      String? imageURL = _existingImageURL;
      String cardId = widget.cardId ?? '';

      if (_isEdit && cardId.isNotEmpty) {
        if (_imageBytes != null) {
          final url = await _storageCardService.uploadCardImage(
            userId: _userId,
            cardId: cardId,
            bytes: _imageBytes!,
          );
          imageURL = url;
        }
        final card = VaultCard(
          id: cardId,
          userId: _userId,
          companyName: company.isEmpty ? null : company,
          personName: person.isEmpty ? null : person,
          phoneNumber: phone.isEmpty ? null : phone,
          address: address.isEmpty ? null : address,
          imageURL: imageURL,
        );
        await _firestoreCardService.updateCard(card);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card updated')),
          );
          Navigator.of(context).pop();
        }
      } else {
        final card = VaultCard(
          id: '',
          userId: _userId,
          companyName: company.isEmpty ? null : company,
          personName: person.isEmpty ? null : person,
          phoneNumber: phone.isEmpty ? null : phone,
          address: address.isEmpty ? null : address,
          imageURL: null,
        );
        cardId = await _firestoreCardService.addCard(card);
        if (_imageBytes != null) {
          final url = await _storageCardService.uploadCardImage(
            userId: _userId,
            cardId: cardId,
            bytes: _imageBytes!,
          );
          await _firestoreCardService.updateCard(
            card.copyWith(id: cardId, imageURL: url),
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card saved')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return PageScaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit card' : 'Add card'),
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
                              _imageSection(),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _companyController,
                                decoration: const InputDecoration(
                                  labelText: 'Company name',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _personController,
                                decoration: const InputDecoration(
                                  labelText: 'Person name',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone number',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: _isEdit ? 'Update card' : 'Save card',
                                icon: Icons.check_rounded,
                                onPressed: _isLoading ? null : _save,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16, width: 16),
                    Expanded(
                      flex: 2,
                      child: _BusinessCardPreview(
                        company: _companyController.text,
                        person: _personController.text,
                        phone: _phoneController.text,
                        address: _addressController.text,
                        imageBytes: _imageBytes,
                        imageURL: _existingImageURL,
                        isWide: isWide,
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

  Widget _imageSection() {
    final hasImage = _imageBytes != null ||
        (_existingImageURL != null && _existingImageURL!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card image',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Colors.white70),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imageBytes != null
                    ? Image.memory(
                        _imageBytes!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        _existingImageURL!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _BusinessCardPreview extends StatelessWidget {
  const _BusinessCardPreview({
    required this.company,
    required this.person,
    required this.phone,
    required this.address,
    this.imageBytes,
    this.imageURL,
    required this.isWide,
  });

  final String company;
  final String person;
  final String phone;
  final String address;
  final Uint8List? imageBytes;
  final String? imageURL;
  final bool isWide;

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
                  if (imageBytes != null || (imageURL != null && imageURL!.isNotEmpty))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              imageURL!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.business_rounded, color: Colors.white70),
                            ),
                    )
                  else
                    const Icon(Icons.shield_rounded, color: Colors.white),
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
              if (person.isNotEmpty)
                Text(
                  person,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (company.isNotEmpty)
                Text(
                  company,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              if (address.isNotEmpty)
                Text(
                  address,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (person.isEmpty && company.isEmpty && phone.isEmpty && address.isEmpty)
                Text(
                  'Your card preview',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
