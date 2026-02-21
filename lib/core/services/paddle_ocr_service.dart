import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:card_vault/core/models/extracted_card_data.dart';
import 'package:card_vault/core/services/card_text_parser.dart';

/// Optional remote PaddleOCR integration.
///
/// To enable:
/// 1) Host a backend endpoint that accepts base64 image payload.
/// 2) Set [_endpoint] to your endpoint URL.
/// 3) If your API needs auth, set [_apiKey] and backend should read
///    `Authorization: Bearer <key>`.
class PaddleOcrService {
  static const String _endpoint = '';
  static const String _apiKey = '';

  static bool get isConfigured => _endpoint.trim().isNotEmpty;

  static Future<ExtractedCardData?> extractCardTextFromImage(
    Uint8List imageBytes,
  ) async {
    if (!isConfigured) return null;

    try {
      final uri = Uri.tryParse(_endpoint.trim());
      if (uri == null) return null;

      final payload = <String, dynamic>{
        'image_base64': base64Encode(imageBytes),
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_apiKey.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_apiKey.trim()}';
      }

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      final structured = _extractStructuredCard(decoded);
      if (structured != null) return structured;

      final rawText = _extractRawText(decoded).trim();
      if (rawText.isEmpty) return null;
      return parseCardText(rawText);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

ExtractedCardData? _extractStructuredCard(dynamic decoded) {
  if (decoded is! Map<String, dynamic>) return null;

  Map<String, dynamic> source = decoded;
  if (decoded['data'] is Map<String, dynamic>) {
    source = decoded['data'] as Map<String, dynamic>;
  } else if (decoded['result'] is Map<String, dynamic>) {
    source = decoded['result'] as Map<String, dynamic>;
  }

  String? pick(List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  final person = pick(const ['personName', 'name', 'full_name', 'person_name']);
  final company = pick(const ['companyName', 'company', 'organization']);
  final phone = pick(const ['phoneNumber', 'phone', 'mobile']);
  final email = pick(const ['email', 'mail']);
  final website = pick(const ['website', 'web', 'url']);
  final address = pick(const ['address', 'location']);
  final businessType = pick(const ['businessType', 'business_type', 'type']);

  final hasAny = [
    person,
    company,
    phone,
    email,
    website,
    address,
    businessType,
  ].any((e) => e != null && e.isNotEmpty);
  if (!hasAny) return null;

  return ExtractedCardData(
    personName: person,
    companyName: company,
    phoneNumber: phone,
    email: email,
    website: website,
    address: address,
    businessType: businessType,
  );
}

String _extractRawText(dynamic decoded) {
  if (decoded is String) return decoded;

  if (decoded is Map<String, dynamic>) {
    final textKeys = ['text', 'raw_text', 'ocr_text', 'full_text', 'content'];
    for (final key in textKeys) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
  }

  final lines = <String>{};
  void walk(dynamic node) {
    if (node is String) {
      final trimmed = node.trim();
      if (trimmed.length >= 2) lines.add(trimmed);
      return;
    }
    if (node is Map) {
      for (final value in node.values) {
        walk(value);
      }
      return;
    }
    if (node is List) {
      for (final value in node) {
        walk(value);
      }
    }
  }

  walk(decoded);
  return lines.join('\n');
}
