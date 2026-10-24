import 'package:intl/intl.dart';

class CurrencyParseResult {
  final int? amountPaise;
  final String? errorMessage;

  const CurrencyParseResult.success(this.amountPaise) : errorMessage = null;
  const CurrencyParseResult.failure(this.errorMessage) : amountPaise = null;

  bool get isSuccess => amountPaise != null;
}

class CurrencyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactInrFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  /// Formats an integer amount in paise into an Indian Rupee string:
  /// e.g. 150000 -> "₹1,500.00"
  static String formatPaiseToInr(int? amountPaise) {
    if (amountPaise == null) return '₹0.00';
    final rupees = amountPaise / 100.0;
    return _inrFormat.format(rupees);
  }

  /// Alias for formatPaiseToInr
  static String formatPaise(int? amountPaise) => formatPaiseToInr(amountPaise);

  /// Compact formatting for metrics cards:
  /// e.g. 50000000 -> "₹5L"
  static String formatPaiseCompact(int? amountPaise) {
    if (amountPaise == null) return '₹0';
    final rupees = amountPaise / 100.0;
    return _compactInrFormat.format(rupees);
  }

  /// Parses user-inputted Rupee string into exact integer paise:
  /// Handles "1500", "1,500.50", "₹ 2,400.00"
  static CurrencyParseResult parseInrToPaise(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const CurrencyParseResult.failure('Amount is required.');
    }

    // Clean currency symbol, commas, and whitespace
    final cleaned = input.replaceAll('₹', '').replaceAll(',', '').trim();

    final parts = cleaned.split('.');
    if (parts.length > 2) {
      return const CurrencyParseResult.failure('Invalid number format.');
    }

    final rupeesStr = parts[0];
    if (rupeesStr.isEmpty && parts.length == 1) {
      return const CurrencyParseResult.failure('Invalid amount.');
    }

    final rupees = int.tryParse(rupeesStr.isEmpty ? '0' : rupeesStr);
    if (rupees == null || rupees < 0) {
      return const CurrencyParseResult.failure('Amount must be positive.');
    }

    int paise = 0;
    if (parts.length == 2) {
      final paiseStr = parts[1];
      if (paiseStr.length > 2) {
        return const CurrencyParseResult.failure(
            'Maximum 2 decimal places allowed.');
      }
      final padded = paiseStr.padRight(2, '0');
      final parsedPaise = int.tryParse(padded);
      if (parsedPaise == null || parsedPaise < 0) {
        return const CurrencyParseResult.failure(
            'Invalid decimal paise amount.');
      }
      paise = parsedPaise;
    }

    final totalPaise = (rupees * 100) + paise;
    return CurrencyParseResult.success(totalPaise);
  }
}
