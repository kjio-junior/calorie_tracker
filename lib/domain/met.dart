import 'activity.dart';

/// MET-based calorie estimates: kcal = MET x body weight (kg) x hours.
/// These are rough averages. Real burn varies by person and effort.
class Met {
  Met._();

  static double kcal({
    required double met,
    required double weightKg,
    required double minutes,
  }) =>
      met * weightKg * minutes / 60;

  static double cardioMet(
    CardioType type, {
    required double minutes,
    double? distanceKm,
  }) {
    final speed = (distanceKm != null && distanceKm > 0 && minutes > 0)
        ? distanceKm / (minutes / 60)
        : null;

    switch (type) {
      case CardioType.run:
        // Running MET is roughly the speed in km/h.
        return speed == null ? 8.0 : speed.clamp(6.0, 20.0).toDouble();
      case CardioType.walk:
        return speed == null ? 3.5 : (0.75 * speed).clamp(2.0, 8.0).toDouble();
      case CardioType.ride:
        if (speed == null) return 6.8;
        if (speed < 16) return 4.0;
        if (speed < 19) return 6.8;
        if (speed < 22) return 8.0;
        if (speed < 26) return 10.0;
        return 12.0;
      case CardioType.hike:
        return 6.0;
      case CardioType.swim:
        return 6.0;
      case CardioType.row:
        return 7.0;
      case CardioType.other:
        return 5.0;
    }
  }

  static double cardioKcal(
    CardioType type, {
    required double minutes,
    required double weightKg,
    double? distanceKm,
  }) =>
      kcal(
        met: cardioMet(type, minutes: minutes, distanceKm: distanceKm),
        weightKg: weightKg,
        minutes: minutes,
      );
}
