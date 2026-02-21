// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:card_vault/core/models/extracted_card_data.dart';
import 'package:card_vault/core/services/card_text_parser.dart';
import 'package:card_vault/core/services/paddle_ocr_service.dart';

/// Calls the global cardVaultOcr(dataUrl) function defined in index.html.
/// Tesseract.js runs in the browser and returns the recognized text.
@JS('cardVaultOcr')
external JSPromise<JSString> _cardVaultOcr(JSString dataUrl);

/// Extracts text from a card image using Tesseract.js (browser).
/// Used on web; on mobile use card_ocr_service_io (ML Kit).
Future<ExtractedCardData?> extractCardTextFromImage(Uint8List imageBytes) async {
  try {
    final paddleResult = await PaddleOcrService.extractCardTextFromImage(imageBytes);
    if (paddleResult != null) return paddleResult;

    final base64 = base64Encode(imageBytes);
    final dataUrl = 'data:image/jpeg;base64,$base64';

    final promise = _cardVaultOcr(dataUrl.toJS);
    final jsResult = await promise.toDart;
    final text = jsResult.toDart;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    return parseCardText(trimmed);
  } catch (_) {
    return null;
  }
}
