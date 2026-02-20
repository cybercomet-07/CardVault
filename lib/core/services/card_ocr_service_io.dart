import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:card_vault/core/models/extracted_card_data.dart';

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

      return _parseCardText(fullText);
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  } catch (_) {
    return null;
  }
}

/// Simple heuristic parser: detect phone, email, then use lines for name/company/address.
ExtractedCardData _parseCardText(String text) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (lines.isEmpty) return const ExtractedCardData();

  String? phoneNumber;
  String? email;
  final otherLines = <String>[];

  final phoneRegex = RegExp(
    r'[\+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]*[0-9]{3,}[-\s\./0-9]*[0-9]{3,}',
  );
  final emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  for (final line in lines) {
    final phoneMatch = phoneRegex.firstMatch(line);
    final emailMatch = emailRegex.firstMatch(line);
    if (phoneMatch != null && phoneNumber == null) {
      phoneNumber = phoneMatch.group(0)?.trim();
    } else if (emailMatch != null && email == null) {
      email = emailMatch.group(0)?.trim();
    } else {
      otherLines.add(line);
    }
  }

  String? personName;
  String? companyName;
  String? address;
  if (otherLines.isNotEmpty) {
    personName = otherLines.first;
    if (otherLines.length >= 2) companyName = otherLines[1];
    if (otherLines.length >= 3) {
      address = otherLines.sublist(2).join(', ');
    }
  }

  return ExtractedCardData(
    personName: personName?.isNotEmpty == true ? personName : null,
    companyName: companyName?.isNotEmpty == true ? companyName : null,
    phoneNumber: phoneNumber?.isNotEmpty == true ? phoneNumber : null,
    email: email?.isNotEmpty == true ? email : null,
    address: address?.isNotEmpty == true ? address : null,
  );
}
