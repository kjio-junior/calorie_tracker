enum MuscleGroup {
  chest('Chest'),
  back('Back'),
  legs('Legs'),
  shoulders('Shoulders'),
  arms('Arms'),
  core('Core');

  const MuscleGroup(this.label);
  final String label;
}

enum Equipment {
  barbell('Barbell'),
  dumbbell('Dumbbell'),
  machine('Machine'),
  cable('Cable'),
  bodyweight('Bodyweight'),
  kettlebell('Kettlebell');

  const Equipment(this.label);
  final String label;
}

/// Rough MET values for resistance training (compendium-style estimates).
enum Intensity {
  light(3.5, 'Light'),
  moderate(5.0, 'Moderate'),
  vigorous(6.0, 'Vigorous');

  const Intensity(this.met, this.label);
  final double met;
  final String label;
}

enum CardioType {
  run('Run'),
  ride('Ride'),
  walk('Walk'),
  hike('Hike'),
  swim('Swim'),
  row('Row'),
  other('Other');

  const CardioType(this.label);
  final String label;
}

class Exercise {
  const Exercise(
    this.id,
    this.name,
    this.group,
    this.equipment, {
    this.timed = false,
  });

  final String id;
  final String name;
  final MuscleGroup group;
  final Equipment equipment;

  /// True when the count is seconds (e.g. plank) instead of reps.
  final bool timed;
}

class WorkoutSet {
  const WorkoutSet({required this.reps, required this.weightKg});

  final int reps;
  final double weightKg;
}

class SessionExercise {
  const SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.group,
    required this.sets,
  });

  final String exerciseId;
  final String name;
  final MuscleGroup group;
  final List<WorkoutSet> sets;
}

class WorkoutSession {
  const WorkoutSession({
    this.id,
    required this.date,
    this.name,
    this.durationMin,
    this.intensity,
    this.estCalories,
    required this.exercises,
  });

  final int? id;
  final String date;
  final String? name;
  final double? durationMin;
  final Intensity? intensity;
  final double? estCalories;
  final List<SessionExercise> exercises;

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets.length);

  double get volumeKg => exercises.fold(
        0.0,
        (s, e) => s + e.sets.fold(0.0, (a, set) => a + set.reps * set.weightKg),
      );

  List<MuscleGroup> get groups {
    final seen = <MuscleGroup>[];
    for (final e in exercises) {
      if (!seen.contains(e.group)) seen.add(e.group);
    }
    return seen;
  }

  String get title {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return groups.map((g) => g.label).join(' + ');
  }
}

class CardioEntry {
  const CardioEntry({
    this.id,
    required this.date,
    required this.type,
    required this.durationMin,
    this.distanceKm,
    this.calories,
  });

  final int? id;
  final String date;
  final CardioType type;
  final double durationMin;
  final double? distanceKm;
  final double? calories;
}
