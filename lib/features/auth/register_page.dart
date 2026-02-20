import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:card_vault/core/router/app_router.dart';
import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/glass_container.dart';
import 'package:card_vault/core/widgets/page_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _buttonHovered = false;

  XFile? _pickedImage;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation;

  static const double _fieldSpacing = 18.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _passwordController.removeListener(() => setState(() {}));
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _companyFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fadeController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  int _passwordStrength(String? value) {
    if (value == null || value.isEmpty) return 0;
    int score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) score++;
    return score.clamp(0, 4);
  }

  String _passwordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color _passwordStrengthColor(int strength) {
    if (strength <= 1) return Colors.red;
    if (strength == 2) return Colors.orange;
    if (strength == 3) return Colors.lightGreen;
    return Colors.green;
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the Terms & Conditions to continue')),
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null && fullName.isNotEmpty) {
        await credential.user!.updateDisplayName(fullName);
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final cardWidth = isWide ? 480.0 : double.infinity;
    final textTheme = Theme.of(context).textTheme;
    final passwordStrength = _passwordStrength(_passwordController.text);

    return PageScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CardVault',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white,
            shadows: [
              Shadow(
                color: AppColors.accentIndigo.withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
              Shadow(
                color: AppColors.accentPurple.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          _AnimatedGradientBackground(animation: _bgAnimation),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 24 : 16,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(28),
                      borderRadius: 20,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create account',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Fill in your details to get started.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: GestureDetector(
                                onTap: _pickProfileImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    _AvatarPreview(pickedImage: _pickedImage),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentIndigo,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.surface, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Add profile photo (optional)',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _GlowTextField(
                              controller: _fullNameController,
                              focusNode: _fullNameFocus,
                              label: 'Full Name',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _GlowTextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _GlowTextField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              label: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _GlowTextField(
                              controller: _companyController,
                              focusNode: _companyFocus,
                              label: 'Company Name (optional)',
                              prefixIcon: Icons.business_outlined,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _GlowTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              label: 'Password',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white54,
                                  size: 22,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (passwordStrength > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Strength: ',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  Text(
                                    _passwordStrengthLabel(passwordStrength),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: _passwordStrengthColor(passwordStrength),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: passwordStrength / 4,
                                        backgroundColor: Colors.white24,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            _passwordStrengthColor(passwordStrength)),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            const SizedBox(height: _fieldSpacing),
                            _GlowTextField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              label: 'Confirm Password',
                              obscureText: _obscureConfirmPassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white54,
                                  size: 22,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: _fieldSpacing),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.25),
                              thickness: 1,
                              height: 24,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (v) =>
                                        setState(() => _acceptedTerms = v ?? false),
                                    fillColor: WidgetStateProperty.resolveWith((s) {
                                      if (s.contains(WidgetState.selected)) {
                                        return AppColors.accentIndigo;
                                      }
                                      return Colors.white24;
                                    }),
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'I agree to the Terms & Conditions and Privacy Policy.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'By signing up you agree to our privacy practices. We never share your data with third parties.',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SignUpButton(
                              isLoading: _isLoading,
                              isHovered: _buttonHovered,
                              onHover: (v) => setState(() => _buttonHovered = v),
                              onPressed: _isLoading ? null : _submit,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      AppRouter.login,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.accentIndigo,
                                  ),
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGradientBackground extends StatelessWidget {
  const _AnimatedGradientBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                Color.lerp(
                  const Color(0xFF020617),
                  AppColors.accentIndigo.withValues(alpha: 0.08),
                  animation.value * 0.5,
                )!,
                Color.lerp(
                  const Color(0xFF0f172a),
                  AppColors.accentPurple.withValues(alpha: 0.06),
                  (1 - animation.value) * 0.5,
                )!,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlowTextField extends StatefulWidget {
  const _GlowTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  State<_GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<_GlowTextField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _GlowTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasFocus = widget.focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: AppColors.accentIndigo.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: Colors.white54, size: 22)
              : null,
          suffixIcon: widget.suffixIcon,
          errorStyle: const TextStyle(color: Colors.redAccent),
          filled: true,
          fillColor: AppColors.surfaceSecondary.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.accentIndigo,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}

class _SignUpButton extends StatelessWidget {
  const _SignUpButton({
    required this.isLoading,
    required this.isHovered,
    required this.onHover,
    this.onPressed,
  });

  final bool isLoading;
  final bool isHovered;
  final void Function(bool) onHover;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentIndigo.withValues(alpha: 0.4),
              blurRadius: isHovered && !isLoading ? 20 : 8,
              spreadRadius: isHovered && !isLoading ? 2 : 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.3),
              blurRadius: isHovered && !isLoading ? 28 : 12,
              spreadRadius: isHovered && !isLoading ? 1 : 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.accentIndigo,
                AppColors.accentPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 24,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded,
                              size: 20, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Sign up'),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({this.pickedImage});

  final XFile? pickedImage;

  @override
  Widget build(BuildContext context) {
    if (pickedImage == null) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: AppColors.surfaceSecondary.withValues(alpha: 0.8),
        child: const Icon(Icons.person_rounded, size: 44, color: Colors.white54),
      );
    }
    return FutureBuilder<dynamic>(
      future: pickedImage!.path.startsWith('blob:') || pickedImage!.path.startsWith('http')
          ? Future<String>.value(pickedImage!.path)
          : pickedImage!.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.surfaceSecondary.withValues(alpha: 0.8),
            child: const Icon(Icons.person_rounded, size: 44, color: Colors.white54),
          );
        }
        final data = snapshot.data!;
        ImageProvider<Object>? provider;
        if (data is String) {
          provider = NetworkImage(data);
        } else {
          provider = MemoryImage(data is Uint8List ? data : Uint8List.fromList(data as List<int>));
        }
        return CircleAvatar(
          radius: 44,
          backgroundColor: AppColors.surfaceSecondary.withValues(alpha: 0.8),
          backgroundImage: provider,
          child: null,
        );
      },
    );
  }
}
