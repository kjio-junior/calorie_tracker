import 'package:flutter/material.dart';

import '../../domain/activity.dart';

IconData cardioIcon(CardioType t) {
  switch (t) {
    case CardioType.run:
      return Icons.directions_run_rounded;
    case CardioType.ride:
      return Icons.directions_bike_rounded;
    case CardioType.walk:
      return Icons.directions_walk_rounded;
    case CardioType.hike:
      return Icons.hiking_rounded;
    case CardioType.swim:
      return Icons.pool_rounded;
    case CardioType.row:
      return Icons.rowing_rounded;
    case CardioType.other:
      return Icons.fitness_center_rounded;
  }
}
