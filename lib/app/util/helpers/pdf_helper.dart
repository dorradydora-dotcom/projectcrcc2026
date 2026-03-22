import 'arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;

class PdfHelper {
  /// Prepared Arabic text for PDF rendering by reshaping and reordering.
  static String prepareArabic(String text) {
    if (text.isEmpty) return text;

    try {
      // 1. Reshape Arabic characters (connect letters)
      final reshaped = ArabicReshaper.instance.reshape(text);

      // 2. Handle Bidirectional reordering (Logical to Visual)
      // نستخدم مكتبة bidi لترتيب الحروف بشكل صحيح للـ PDF الـ RTL
      return String.fromCharCodes(bidi.logicalToVisual(reshaped));
    } catch (e) {
      // Fallback to original text if reshaping fails
      return text;
    }
  }

  /// Specialized helper for page numbering to ensure "Page X of Y" logic
  /// renders correctly in RTL contexts.
  static String formatPageNumber(int current, int total) {
    // In Arabic, we want "صفحة 1 من 5"
    final text = 'صفحة $current من $total';
    return prepareArabic(text);
  }
}
