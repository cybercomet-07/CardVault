import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:card_vault/core/models/extracted_card_data.dart';
import 'package:card_vault/core/services/card_text_parser.dart';

/// Extracts text from a card image using ML Kit and parses into structured fields.
/// Used on Android/iOS only; on web use the stub.
Future<ExtractedCardData?> extractCardTextFromImage(Uint8List imageBytes) async {
  try {
    final tempFile = File('${Directory.systemTemp.path}/cardvault_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);
    try {
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final String fullText = recognizedText.text.trim();
      if (fullText.isEmpty) return null;

      return parseCardText(fullText);
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  } catch (_) {
    return null;
  }
}
