/// Result of OCR extraction from a card image.
class ExtractedCardData {
  const ExtractedCardData({
    this.personName,
    this.companyName,
    this.phoneNumber,
    this.email,
    this.website,
    this.address,
    this.businessType,
  });

  final String? personName;
  final String? companyName;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? address;
  final String? businessType;
}
