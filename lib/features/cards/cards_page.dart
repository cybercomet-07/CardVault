import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:card_vault/core/models/vault_card.dart';
import 'package:card_vault/core/services/card_ocr_service_stub.dart'
    if (dart.library.io) 'package:card_vault/core/services/card_ocr_service_io.dart'
    if (dart.library.html) 'package:card_vault/core/services/card_ocr_service_web.dart' as card_ocr;
import 'package:card_vault/core/services/firestore_card_service.dart';
import 'package:card_vault/core/services/storage_card_service.dart';
import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';
import 'package:card_vault/core/widgets/primary_button.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key, this.initialCardId});

  /// If set, load this card into the form on init (e.g. from Dashboard Edit).
  final String? initialCardId;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  final _firestoreCardService = FirestoreCardService();
  final _storageCardService = StorageCardService();
  final _listScrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  final _personController = TextEditingController();
  final _companyController = TextEditingController();
  final _designationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedBusinessType = 'Other';

  String? _selectedCardId;
  Uint8List? _imageBytes;
  String? _existingImageURL;
  bool _isSaving = false;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(\/.*)?$',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialCardId != null && widget.initialCardId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialCard());
    }
  }

  Future<void> _loadInitialCard() async {
    final id = widget.initialCardId!;
    final card = await _firestoreCardService.getCard(id);
    if (card != null && mounted) _loadCardIntoForm(card);
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _personController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _selectedCardId = null;
    _personController.clear();
    _companyController.clear();
    _designationController.clear();
    _phoneController.clear();
    _emailController.clear();
    _websiteController.clear();
    _addressController.clear();
    _notesController.clear();
    _selectedBusinessType = 'Other';
    _imageBytes = null;
    _existingImageURL = null;
    setState(() {});
  }

  void _loadCardIntoForm(VaultCard card) {
    _selectedCardId = card.id;
    _personController.text = card.personName ?? '';
    _companyController.text = card.companyName ?? '';
    _designationController.text = card.designation ?? '';
    _phoneController.text = card.phoneNumber ?? '';
    _emailController.text = card.email ?? '';
    _websiteController.text = card.website ?? '';
    _addressController.text = card.address ?? '';
    _notesController.text = card.notes ?? '';
    _selectedBusinessType = (card.businessType ?? '').trim().isNotEmpty
        ? card.businessType!
        : 'Other';
    _existingImageURL = card.imageURL;
    _imageBytes = null;
    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final granted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Camera access'),
          content: const Text(
            'Allow camera access when your browser or device prompts you.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
          ],
        ),
      );
      if (granted != true || !mounted) return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() => _imageBytes = bytes);
        // Extract text from image (OCR on mobile; no-op on web) and pre-fill form
        final extracted = await card_ocr.extractCardTextFromImage(bytes);
        if (extracted != null && mounted) {
          if ((extracted.personName ?? '').trim().isNotEmpty) _personController.text = extracted.personName!.trim();
          if ((extracted.companyName ?? '').trim().isNotEmpty) _companyController.text = extracted.companyName!.trim();
          if ((extracted.phoneNumber ?? '').trim().isNotEmpty) _phoneController.text = extracted.phoneNumber!.trim();
          if ((extracted.email ?? '').trim().isNotEmpty) _emailController.text = extracted.email!.trim();
          if ((extracted.website ?? '').trim().isNotEmpty) _websiteController.text = extracted.website!.trim();
          if ((extracted.address ?? '').trim().isNotEmpty) _addressController.text = extracted.address!.trim();
          if ((extracted.businessType ?? '').trim().isNotEmpty) {
            _selectedBusinessType = extracted.businessType!;
          }
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text extracted from image. Edit if needed, then save.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Access denied.'), backgroundColor: Colors.orange.shade800),
        );
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_emailRegex.hasMatch(s)) return 'Enter a valid email';
    return null;
  }

  String? _validateWebsite(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    if (s.isNotEmpty && !_urlRegex.hasMatch(s)) return 'Enter a valid URL';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final person = _personController.text.trim();
      final company = _companyController.text.trim();
      final designation = _designationController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final website = _websiteController.text.trim();
      final address = _addressController.text.trim();
      final notes = _notesController.text.trim();

      String? imageURL = _existingImageURL;
      String? cardId = _selectedCardId;

      if (cardId != null && cardId.isNotEmpty) {
        if (_imageBytes != null) {
          imageURL = await _storageCardService.uploadCardImage(
            userId: _userId,
            cardId: cardId,
            bytes: _imageBytes!,
          );
        }
        final card = VaultCard(
          id: cardId,
          userId: _userId,
          personName: person,
          companyName: company,
          businessType: _selectedBusinessType,
          designation: designation.isEmpty ? null : designation,
          phoneNumber: phone,
          email: email.isEmpty ? null : email,
          website: website.isEmpty ? null : website,
          address: address.isEmpty ? null : address,
          notes: notes.isEmpty ? null : notes,
          imageURL: imageURL,
        );
        await _firestoreCardService.updateCard(card);
      } else {
        final card = VaultCard(
          id: '',
          userId: _userId,
          personName: person,
          companyName: company,
          businessType: _selectedBusinessType,
          designation: designation.isEmpty ? null : designation,
          phoneNumber: phone,
          email: email.isEmpty ? null : email,
          website: website.isEmpty ? null : website,
          address: address.isEmpty ? null : address,
          notes: notes.isEmpty ? null : notes,
          imageURL: null,
        );
        cardId = await _firestoreCardService.addCard(card);
        if (_imageBytes != null) {
          imageURL = await _storageCardService.uploadCardImage(
            userId: _userId,
            cardId: cardId,
            bytes: _imageBytes!,
          );
          await _firestoreCardService.updateCard(
            card.copyWith(id: cardId, imageURL: imageURL),
          );
        }
      }

      if (mounted) {
        _clearForm();
        _listScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Card saved successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteCard(String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This card will be removed from your vault.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      if (_selectedCardId == cardId) _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card deleted'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showImageModal(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsPanel(VaultCard card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.personName?.trim().isNotEmpty == true ? card.personName! : '—',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _detailRow('Company', card.companyName),
            _detailRow('Business type', card.businessType),
            _detailRow('Designation', card.designation),
            _detailRow('Phone', card.phoneNumber),
            _detailRow('Email', card.email),
            _detailRow('Website', card.website),
            _detailRow('Address', card.address),
            if (card.notes?.trim().isNotEmpty == true) _detailRow('Notes', card.notes),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadCardIntoForm(card);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentIndigo,
                      side: const BorderSide(color: AppColors.accentIndigo),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteCard(card.id);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= 900;
          return Flex(
            direction: split ? Axis.horizontal : Axis.vertical,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent cards',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<List<VaultCard>>(
                            stream: _firestoreCardService.streamCards(_userId),
                            builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                              return _ShimmerCardList();
                            }
                            final cards = snapshot.data ?? [];
                            if (cards.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.credit_card_off_rounded, size: 64, color: Colors.white24),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No cards yet',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white54),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add your first card using the form on the right.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              controller: _listScrollController,
                              itemCount: cards.length,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                final isSelected = _selectedCardId == card.id;
                                return _CardListTile(
                                  card: card,
                                  isSelected: isSelected,
                                  onTap: () {
                                    if (card.imageURL != null && card.imageURL!.isNotEmpty) {
                                      _showImageModal(card.imageURL!);
                                    } else {
                                      _showDetailsPanel(card);
                                    }
                                  },
                                  onEdit: () => _loadCardIntoForm(card),
                                  onDelete: () => _deleteCard(card.id),
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCardId != null ? 'Edit card' : 'Add new card',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          const SizedBox(height: 20),
                          _sectionLabel('Basic info'),
                          const SizedBox(height: 10),
                          _field(_personController, 'Person name *', validator: (v) => _validateRequired(v, 'Person name')),
                          const SizedBox(height: 12),
                          _field(_companyController, 'Company name *', validator: (v) => _validateRequired(v, 'Company name')),
                          const SizedBox(height: 12),
                          _businessTypeDropdown(),
                          const SizedBox(height: 12),
                          _field(_designationController, 'Designation (optional)'),
                          const SizedBox(height: 20),
                          _sectionLabel('Contact info'),
                          const SizedBox(height: 10),
                          _field(_phoneController, 'Phone number *', keyboardType: TextInputType.phone, validator: (v) => _validateRequired(v, 'Phone number')),
                          const SizedBox(height: 12),
                          _field(_emailController, 'Email (optional)', keyboardType: TextInputType.emailAddress, validator: _validateEmail),
                          const SizedBox(height: 12),
                          _field(_websiteController, 'Website (optional)', keyboardType: TextInputType.url, validator: _validateWebsite),
                          const SizedBox(height: 12),
                          _field(_addressController, 'Office address (optional)', maxLines: 2),
                          const SizedBox(height: 20),
                          _sectionLabel('Additional'),
                          const SizedBox(height: 10),
                          _field(_notesController, 'Notes (optional)', maxLines: 2),
                          const SizedBox(height: 20),
                          _sectionLabel('Image (optional)'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _ImageButton(icon: Icons.upload_file_rounded, label: 'Upload', onTap: () => _pickImage(ImageSource.gallery)),
                              const SizedBox(width: 12),
                              _ImageButton(icon: Icons.camera_alt_rounded, label: 'Capture', onTap: () => _pickImage(ImageSource.camera)),
                            ],
                          ),
                          if (_imageBytes != null || (_existingImageURL != null && _existingImageURL!.isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageBytes != null
                                  ? Image.memory(_imageBytes!, height: 120, width: double.infinity, fit: BoxFit.cover)
                                  : Image.network(
                                      _existingImageURL!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: _isSaving ? 'Saving...' : (_selectedCardId != null ? 'Update card' : 'Save card'),
                              icon: _isSaving ? null : Icons.check_rounded,
                              onPressed: _isSaving ? null : _save,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.accentIndigo.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceSecondary.withValues(alpha: 0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _businessTypeDropdown() {
    const options = [
      'Technology',
      'Healthcare',
      'Finance',
      'Marketing',
      'Retail',
      'Education',
      'Hospitality',
      'Manufacturing',
      'Consulting',
      'Other',
    ];
    return DropdownButtonFormField<String>(
      initialValue: options.contains(_selectedBusinessType) ? _selectedBusinessType : 'Other',
      decoration: InputDecoration(
        labelText: 'Business type',
        filled: true,
        fillColor: AppColors.surfaceSecondary.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: options
          .map((t) => DropdownMenuItem<String>(
                value: t,
                child: Text(t),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedBusinessType = value);
      },
    );
  }
}

class _CardListTile extends StatelessWidget {
  const _CardListTile({
    required this.card,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final VaultCard card;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final personName = card.personName?.trim().isNotEmpty == true ? card.personName! : '—';
    final companyName = card.companyName?.trim().isNotEmpty == true ? card.companyName! : '—';
    final phone = card.phoneNumber?.trim().isNotEmpty == true ? card.phoneNumber! : '—';
    final hasImage = card.imageURL != null && card.imageURL!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? AppColors.accentIndigo.withValues(alpha: 0.25)
            : AppColors.surfaceSecondary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      card.imageURL!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
                    ),
                  ),
                if (hasImage) const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(personName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(companyName, style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      Text(phone, style: textTheme.bodySmall?.copyWith(color: Colors.white54)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outlined, size: 20, color: Colors.redAccent), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageButton extends StatelessWidget {
  const _ImageButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentIndigo.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCardList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
