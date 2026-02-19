/// OCR data source (ML Kit on mobile, fallback on web).
abstract class OcrDataSource {
  Future<String> extractTextFromImage(List<int> imageBytes);
}
