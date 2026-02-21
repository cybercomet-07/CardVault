import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class StorageCardService {
  static const String _cloudName = 'dnroofpld';
  static const String _uploadPreset = 'cardvault_cards';

  /// Upload card image to Cloudinary; returns the hosted image URL.
  Future<String> uploadCardImage({
    required String userId,
    required String cardId,
    required Uint8List bytes,
  }) async {
    final firstTry = await _upload(
      bytes: bytes,
      cardId: cardId,
      folder: 'cardvault/cards/$userId',
    );
    if (firstTry != null) return firstTry;

    // Some unsigned presets reject folder-related params.
    final secondTry = await _upload(
      bytes: bytes,
      cardId: cardId,
    );
    if (secondTry != null) return secondTry;

    throw Exception('Cloudinary upload failed after retry.');
  }

  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
  }) async {
    final profileId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final firstTry = await _upload(
      bytes: bytes,
      cardId: profileId,
      folder: 'cardvault/profiles/$userId',
    );
    if (firstTry != null) return firstTry;

    final secondTry = await _upload(
      bytes: bytes,
      cardId: profileId,
    );
    if (secondTry != null) return secondTry;

    throw Exception('Cloudinary profile upload failed after retry.');
  }

  Future<String?> _upload({
    required Uint8List bytes,
    required String cardId,
    String? folder,
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$cardId.jpg',
        ),
      );
    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = (json['secure_url'] ?? json['url']) as String?;
    if (secureUrl == null || secureUrl.isEmpty) return null;
    return secureUrl;
  }
}
