import 'package:flutter/foundation.dart';
import 'print_service_stub.dart'
    if (dart.library.html) 'print_service_web.dart' as platform_print;

class PrintService {
  PrintService._();

  /// Triggers the native platform/browser print dialog.
  static void printDocument() {
    if (kIsWeb) {
      platform_print.triggerBrowserPrint();
    } else {
      debugPrint('[PrintService] Native print requested.');
    }
  }
}
