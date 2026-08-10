import 'package:intl/intl.dart';

const kDefaultCurrencyCode = 'IDR';

const kCommonCurrencyCodes = <String>[
  'IDR',
  'USD',
  'EUR',
  'SGD',
  'AUD',
  'GBP',
  'JPY',
];

String normalizeCurrencyCode(String raw) {
  final code = raw.trim().toUpperCase();
  if (code.length != 3 || !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
    throw ArgumentError('Currency must be a 3-letter ISO code');
  }
  return code;
}

String formatMoney(num amount, String currencyCode) {
  try {
    return NumberFormat.simpleCurrency(name: currencyCode).format(amount);
  } catch (_) {
    return NumberFormat.currency(name: currencyCode, symbol: '$currencyCode ')
        .format(amount);
  }
}
