import 'dart:typed_data';

import 'package:card_vault/core/models/extracted_card_data.dart';

/// Stub implementation (used on web where ML Kit is not available).
/// Returns null so the app still builds and runs on web.
Future<ExtractedCardData?> extractCardTextFromImage(Uint8List imageBytes) async {
  return null;
}
