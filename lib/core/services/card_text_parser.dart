import 'package:card_vault/core/models/extracted_card_data.dart';

/// Parses raw OCR text into structured card fields.
/// Shared by ML Kit (mobile) and Tesseract.js (web).
ExtractedCardData parseCardText(String text) {
  final rawLines = text
      .split(RegExp(r'\r?\n'))
      .map((s) => _normalizeLine(s))
      .where((s) => s.isNotEmpty)
      .toList();
  if (rawLines.isEmpty) return const ExtractedCardData();

  String? phoneNumber;
  String? email;
  final websiteRegex = RegExp(r'(https?:\/\/|www\.)[a-zA-Z0-9\.-]+\.[a-zA-Z]{2,}');
  final addressHints = RegExp(
    r'\b(st|street|rd|road|ave|avenue|blvd|drive|dr|suite|floor|city|state|country|zip)\b',
    caseSensitive: false,
  );

  String? website;
  String? address;
  final otherLines = <String>[];

  final phoneRegex = RegExp(
    r'[\+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]*[0-9]{3,}[-\s\./0-9]*[0-9]{3,}',
  );
  final emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  for (final line in rawLines) {
    if (_isNoisyLine(line)) continue;

    final phoneMatch = phoneRegex.firstMatch(line);
    final emailMatch = emailRegex.firstMatch(line);
    final websiteMatch = websiteRegex.firstMatch(line);

    if (phoneMatch != null && phoneNumber == null) {
      phoneNumber = phoneMatch.group(0)?.trim();
    } else if (emailMatch != null && email == null) {
      email = emailMatch.group(0)?.trim();
    } else if (websiteMatch != null && website == null) {
      website = websiteMatch.group(0)?.trim();
    } else if (address == null &&
        (addressHints.hasMatch(line) || RegExp(r'\d{2,}').hasMatch(line))) {
      address = line;
    } else {
      otherLines.add(line);
    }
  }

  final candidates = otherLines.where(_looksLikeNameOrCompany).toList();
  String? personName;
  String? companyName;

  if (candidates.isNotEmpty) {
    personName = candidates.first;
    if (candidates.length >= 2) {
      companyName = candidates[1];
    } else if (rawLines.length >= 2) {
      companyName = rawLines[1];
    }
  } else if (rawLines.isNotEmpty) {
    personName = rawLines.first;
  }

  if ((address == null || address.isEmpty) && otherLines.length >= 3) {
    address = otherLines.skip(2).take(2).join(', ');
  }

  final inferredCompany = _companyFromEmailOrWebsite(email, website);
  if ((companyName == null || _isLikelyNoisy(companyName)) && inferredCompany != null) {
    companyName = inferredCompany;
  }

  return ExtractedCardData(
    personName: _cleanOutput(personName),
    companyName: _cleanOutput(companyName),
    phoneNumber: phoneNumber?.isNotEmpty == true ? phoneNumber : null,
    email: email?.isNotEmpty == true ? email : null,
    website: _cleanOutput(website),
    address: _cleanOutput(address),
    businessType: _inferBusinessType(
      source: [
        if (companyName != null) companyName,
        if (personName != null) personName,
        if (website != null) website,
        ...otherLines,
      ].join(' '),
    ),
  );
}

String _normalizeLine(String input) {
  final normalized = input
      .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return normalized;
}

bool _isNoisyLine(String line) {
  if (line.length < 2) return true;
  final alphaNum = RegExp(r'[a-zA-Z0-9]').allMatches(line).length;
  final symbols = RegExp(r'[^a-zA-Z0-9\s]').allMatches(line).length;
  return alphaNum == 0 || symbols > alphaNum;
}

bool _looksLikeNameOrCompany(String line) {
  if (line.length < 3 || line.length > 50) return false;
  if (RegExp(r'\d{3,}').hasMatch(line)) return false;
  final words = line.split(' ').where((w) => w.trim().isNotEmpty).toList();
  if (words.isEmpty || words.length > 6) return false;
  final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
  final nonSpace = line.replaceAll(' ', '').length;
  if (letters < 3) return false;
  if (nonSpace > 0 && (letters / nonSpace) < 0.55) return false;
  return RegExp(r'[A-Za-z]{2,}').hasMatch(line);
}

String? _cleanOutput(String? value) {
  if (value == null) return null;
  final v = value
      .replaceAll(RegExp("[^A-Za-z0-9@&+.,:/()\\-' ]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (v.isEmpty) return null;
  if (RegExp(r'[A-Za-z]').allMatches(v).length < 2) return null;
  return v;
}

bool _isLikelyNoisy(String? value) {
  if (value == null || value.trim().isEmpty) return true;
  final v = value.trim();
  final letters = RegExp(r'[A-Za-z]').allMatches(v).length;
  final nonSpace = v.replaceAll(' ', '').length;
  if (letters < 2) return true;
  return nonSpace > 0 && (letters / nonSpace) < 0.5;
}

String? _companyFromEmailOrWebsite(String? email, String? website) {
  String? host;
  if (email != null && email.contains('@')) {
    host = email.split('@').last;
  } else if (website != null) {
    host = website
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .split('/').first;
  }
  if (host == null || host.isEmpty) return null;
  final label = host.split('.').first;
  if (label.isEmpty) return null;
  return label[0].toUpperCase() + label.substring(1).toLowerCase();
}

String _inferBusinessType({required String source}) {
  final s = source.toLowerCase();
  if (s.contains('tech') || s.contains('software') || s.contains('it ') || s.contains('digital')) {
    return 'Technology';
  }
  if (s.contains('hospital') || s.contains('clinic') || s.contains('health') || s.contains('pharma')) {
    return 'Healthcare';
  }
  if (s.contains('bank') || s.contains('finance') || s.contains('fintech') || s.contains('insurance')) {
    return 'Finance';
  }
  if (s.contains('market') || s.contains('branding') || s.contains('media') || s.contains('advert')) {
    return 'Marketing';
  }
  if (s.contains('school') || s.contains('college') || s.contains('university') || s.contains('education')) {
    return 'Education';
  }
  if (s.contains('retail') || s.contains('store') || s.contains('shop') || s.contains('ecommerce')) {
    return 'Retail';
  }
  if (s.contains('hotel') || s.contains('restaurant') || s.contains('cafe') || s.contains('hospitality')) {
    return 'Hospitality';
  }
  if (s.contains('factory') || s.contains('manufactur') || s.contains('industrial')) {
    return 'Manufacturing';
  }
  if (s.contains('consult') || s.contains('advisory') || s.contains('services')) {
    return 'Consulting';
  }
  return 'Other';
}
