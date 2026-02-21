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
  final _designationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedBusinessType = 'Other';

  final _firestoreCardService = FirestoreCardService();
  final _storageCardService = StorageCardService();

  bool _isLoading = false;
  bool _isEdit = false;
  Uint8List? _imageBytes;
  String? _existingImageURL;

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
      setState(() {});
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _personController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final granted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Camera access'),
          content: const Text(
            'CardVault will request camera access to capture your business card. '
            'Allow access when your browser or device prompts you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
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
          SnackBar(
            content: Text(
              e.message ?? 'Camera or gallery access was denied.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final company = _companyController.text.trim();
      final person = _personController.text.trim();
      final designation = _designationController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final website = _websiteController.text.trim();
      final address = _addressController.text.trim();
      final notes = _notesController.text.trim();

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
          businessType: _selectedBusinessType,
          designation: designation.isEmpty ? null : designation,
          phoneNumber: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          website: website.isEmpty ? null : website,
          address: address.isEmpty ? null : address,
          notes: notes.isEmpty ? null : notes,
          imageURL: imageURL,
        );
        await _firestoreCardService.updateCard(card);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Card updated successfully'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        final card = VaultCard(
          id: '',
          userId: _userId,
          companyName: company.isEmpty ? null : company,
          personName: person.isEmpty ? null : person,
          businessType: _selectedBusinessType,
          designation: designation.isEmpty ? null : designation,
          phoneNumber: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          website: website.isEmpty ? null : website,
          address: address.isEmpty ? null : address,
          notes: notes.isEmpty ? null : notes,
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
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
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
        title: Text(_isEdit ? 'Edit card' : 'Add business card'),
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
                  direction: showSideBySide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _imageSection(),
                                const SizedBox(height: 28),
                                _sectionTitle('Basic info'),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _companyController,
                                  label: 'Company name',
                                  hint: 'e.g. Acme Inc.',
                                  validator: _validateCompanyOrPerson,
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _personController,
                                  label: 'Person name',
                                  hint: 'Full name',
                                  validator: _validateCompanyOrPerson,
                                ),
                                const SizedBox(height: 14),
                                _businessTypeDropdown(),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _designationController,
                                  label: 'Designation',
                                  hint: 'e.g. Product Manager',
                                ),
                                const SizedBox(height: 24),
                                _sectionTitle('Contact info'),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _phoneController,
                                  label: 'Phone number',
                                  hint: '+1 234 567 8900',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'name@company.com',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _websiteController,
                                  label: 'Website',
                                  hint: 'https://company.com',
                                  keyboardType: TextInputType.url,
                                  validator: _validateWebsite,
                                ),
                                const SizedBox(height: 24),
                                _sectionTitle('Additional info'),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _addressController,
                                  label: 'Office address',
                                  hint: 'Street, city, country',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _notesController,
                                  label: 'Notes (optional)',
                                  hint: 'Any extra details',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 32),
                                _AnimatedSaveButton(
                                  label: _isEdit ? 'Update card' : 'Save card',
                                  isLoading: _isLoading,
                                  onPressed: _save,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
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
                        designation: _designationController.text,
                        phone: _phoneController.text,
                        email: _emailController.text,
                        website: _websiteController.text,
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

  String? _validateCompanyOrPerson(String? value) {
    final company = _companyController.text.trim();
    final person = _personController.text.trim();
    if (company.isEmpty && person.isEmpty) {
      return 'Enter at least company name or person name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_emailRegex.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  String? _validateWebsite(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_urlRegex.hasMatch(s) && s.isNotEmpty) {
      return 'Enter a valid URL (e.g. https://...)';
    }
    return null;
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.accentIndigo.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.surfaceSecondary.withValues(alpha: 0.6),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.surfaceSecondary.withValues(alpha: 0.6),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _imageSection() {
    final hasImage = _imageBytes != null ||
        (_existingImageURL != null && _existingImageURL!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business card image',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _ImageActionButton(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 12),
            _ImageActionButton(
              icon: Icons.upload_file_rounded,
              label: 'Upload',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
        if (hasImage) ...[
          const SizedBox(height: 14),
          Text(
            'Live preview',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _imageBytes != null
                ? Image.memory(
                    _imageBytes!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  )
                : Image.network(
                    _existingImageURL!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class _ImageActionButton extends StatefulWidget {
  const _ImageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ImageActionButton> createState() => _ImageActionButtonState();
}

class _ImageActionButtonState extends State<_ImageActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentIndigo.withValues(
              alpha: _hover ? 0.45 : 0.28,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover ? AppColors.accentIndigo : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white.withValues(alpha: 0.95), size: 22),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSaveButton extends StatefulWidget {
  const _AnimatedSaveButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<_AnimatedSaveButton>
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
    final child = widget.isLoading
        ? _loadingButton()
        : PrimaryButton(
            label: widget.label,
            icon: Icons.check_rounded,
            onPressed: widget.onPressed,
            isExpanded: true,
          );
    return ScaleTransition(scale: _scale, child: child);
  }

  Widget _loadingButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentIndigo.withValues(alpha: 0.7),
            AppColors.accentPurple.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('Saving...', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessCardPreview extends StatelessWidget {
  const _BusinessCardPreview({
    required this.company,
    required this.person,
    required this.designation,
    required this.phone,
    required this.email,
    required this.website,
    required this.address,
    this.imageBytes,
    this.imageURL,
    required this.isWide,
  });

  final String company;
  final String person;
  final String designation;
  final String phone;
  final String email;
  final String website;
  final String address;
  final Uint8List? imageBytes;
  final String? imageURL;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = imageBytes != null || (imageURL != null && imageURL!.isNotEmpty);

    return Align(
      alignment: isWide ? Alignment.centerRight : Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Preview',
            style: textTheme.titleSmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
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
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(
                          image: imageBytes != null
                              ? MemoryImage(imageBytes!)
                              : NetworkImage(imageURL!) as ImageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _textPreview(textTheme),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black26,
                                Colors.black54,
                                Colors.black87,
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (person.isNotEmpty)
                                Text(
                                  person,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (company.isNotEmpty)
                                Text(
                                  company,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _textPreview(textTheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textPreview(TextTheme textTheme) {
    final empty = person.isEmpty &&
        company.isEmpty &&
        designation.isEmpty &&
        phone.isEmpty &&
        email.isEmpty &&
        website.isEmpty &&
        address.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
          if (designation.isNotEmpty)
            Text(
              designation,
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          if (company.isNotEmpty)
            Text(
              company,
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          if (phone.isNotEmpty)
            Text(
              phone,
              style: textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          if (email.isNotEmpty)
            Text(
              email,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (address.isNotEmpty)
            Text(
              address,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (empty)
            Text(
              'Your card preview',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
        ],
      ),
    );
  }
}
