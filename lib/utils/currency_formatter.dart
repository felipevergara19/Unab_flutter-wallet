import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter
        .format(amount)
        .replaceAll(
          ',',
          '.',
        ); // Ensure dot separation if locale differs slightly in implementation
  }
}
