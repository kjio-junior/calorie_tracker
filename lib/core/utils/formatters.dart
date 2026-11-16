class Fmt {
  Fmt._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// yyyy-MM-dd, the key used for every per-day row in SQLite.
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime parseKey(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  /// 150.0 -> "150", 1.5 -> "1.5"
  static String amount(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class Units {
  Units._();

  static const double kgPerLb = 0.45359237;

  static double fromKg(double kg, bool lbs) => lbs ? kg / kgPerLb : kg;
  static double toKg(double value, bool lbs) => lbs ? value * kgPerLb : value;
  static String unit(bool lbs) => lbs ? 'lb' : 'kg';

  static String weight(double kg, bool lbs, {int decimals = 1}) =>
      '${fromKg(kg, lbs).toStringAsFixed(decimals)} ${unit(lbs)}';
}
