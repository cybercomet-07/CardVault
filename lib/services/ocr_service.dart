/// OCR: ML Kit (mobile) or web fallback; used by [OcrDataSource].
abstract class OcrService {
  Future<String> extractText(List<int> imageBytes);
}
