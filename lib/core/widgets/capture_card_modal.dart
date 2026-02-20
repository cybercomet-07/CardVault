import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:card_vault/core/theme/app_theme.dart';

/// Shows a modal to capture a card image via camera.
/// Returns [Uint8List] on success, null on cancel or error.
/// Handles permission prompt and loading state.
class CaptureCardModal {
  static Future<Uint8List?> show(BuildContext context) async {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _CaptureCardDialog(),
    );
  }
}

class _CaptureCardDialog extends StatefulWidget {
  const _CaptureCardDialog();

  @override
  State<_CaptureCardDialog> createState() => _CaptureCardDialogState();
}

class _CaptureCardDialogState extends State<_CaptureCardDialog> {
  bool _isCapturing = false;
  String? _error;

  Future<void> _capture() async {
    setState(() {
      _isCapturing = true;
      _error = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (picked == null || !mounted) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      if (mounted) Navigator.of(context).pop(Uint8List.fromList(bytes));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _error = e.toString().contains('Permission') || e.toString().contains('denied')
              ? 'Camera access was denied.'
              : 'Failed to capture: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_rounded, color: AppColors.accentIndigo),
          SizedBox(width: 12),
          Text('Capture card'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allow camera access when your browser or device prompts you. '
            'Then tap Capture to take a photo of your business card.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(color: Colors.orange.shade200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCapturing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isCapturing ? null : _capture,
          icon: _isCapturing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_rounded, size: 20),
          label: Text(_isCapturing ? 'Opening camera...' : 'Capture'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentIndigo,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
