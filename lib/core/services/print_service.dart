import 'package:flutter/foundation.dart';
import 'print_service_stub.dart' if (dart.library.html) 'print_service_web.dart'
    as platform_print;

class PrintService {
  PrintService._();

  /// Triggers clean, document-only printing.
  ///
  /// Writes the isolated document with authoritative letterhead, typography,
  /// and @page styling to an isolated print context. NEVER invokes print on the
  /// root application window, completely preventing dark modal backdrops, navigation bars,
  /// sidebars, and application chrome from polluting the printout.
  static void printDocument({
    String? htmlContent,
    String documentTitle = 'LAV Academy Document',
  }) {
    if (kIsWeb) {
      if (htmlContent != null && htmlContent.isNotEmpty) {
        platform_print.printHtmlDocument(
          htmlContent: htmlContent,
          documentTitle: documentTitle,
        );
      } else {
        // Intentionally do nothing instead of capturing the entire application shell
        debugPrint(
            '[PrintService] Web print requested without authoritative HTML content; skipping full-page print.');
      }
    } else {
      debugPrint('[PrintService] Native print requested for "$documentTitle".');
    }
  }
}
