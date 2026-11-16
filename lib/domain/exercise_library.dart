import 'activity.dart';

/// Pre-seeded offline exercise library, organised by muscle group.
const List<Exercise> kExerciseLibrary = [
  // Chest
  Exercise('bench_press', 'Barbell Bench Press', MuscleGroup.chest, Equipment.barbell),
  Exercise('incline_db_press', 'Incline Dumbbell Press', MuscleGroup.chest, Equipment.dumbbell),
  Exercise('decline_bench', 'Decline Bench Press', MuscleGroup.chest, Equipment.barbell),
  Exercise('db_fly', 'Dumbbell Fly', MuscleGroup.chest, Equipment.dumbbell),
  Exercise('cable_crossover', 'Cable Crossover', MuscleGroup.chest, Equipment.cable),
  Exercise('chest_press_machine', 'Chest Press Machine', MuscleGroup.chest, Equipment.machine),
  Exercise('push_up', 'Push-Up', MuscleGroup.chest, Equipment.bodyweight),
  Exercise('chest_dip', 'Chest Dip', MuscleGroup.chest, Equipment.bodyweight),

  // Back
  Exercise('deadlift', 'Deadlift', MuscleGroup.back, Equipment.barbell),
  Exercise('barbell_row', 'Barbell Row', MuscleGroup.back, Equipment.barbell),
  Exercise('pull_up', 'Pull-Up', MuscleGroup.back, Equipment.bodyweight),
  Exercise('chin_up', 'Chin-Up', MuscleGroup.back, Equipment.bodyweight),
  Exercise('lat_pulldown', 'Lat Pulldown', MuscleGroup.back, Equipment.cable),
  Exercise('seated_cable_row', 'Seated Cable Row', MuscleGroup.back, Equipment.cable),
  Exercise('one_arm_db_row', 'One-Arm Dumbbell Row', MuscleGroup.back, Equipment.dumbbell),
  Exercise('back_extension', 'Back Extension', MuscleGroup.back, Equipment.bodyweight),

  // Legs
  Exercise('back_squat', 'Barbell Squat', MuscleGroup.legs, Equipment.barbell),
  Exercise('leg_press', 'Leg Press', MuscleGroup.legs, Equipment.machine),
  Exercise('romanian_deadlift', 'Romanian Deadlift', MuscleGroup.legs, Equipment.barbell),
  Exercise('walking_lunge', 'Walking Lunge', MuscleGroup.legs, Equipment.dumbbell),
  Exercise('bulgarian_split_squat', 'Bulgarian Split Squat', MuscleGroup.legs, Equipment.dumbbell),
  Exercise('goblet_squat', 'Goblet Squat', MuscleGroup.legs, Equipment.kettlebell),
  Exercise('leg_extension', 'Leg Extension', MuscleGroup.legs, Equipment.machine),
  Exercise('leg_curl', 'Leg Curl', MuscleGroup.legs, Equipment.machine),
  Exercise('calf_raise', 'Calf Raise', MuscleGroup.legs, Equipment.machine),

  // Shoulders
  Exercise('overhead_press', 'Overhead Press', MuscleGroup.shoulders, Equipment.barbell),
  Exercise('db_shoulder_press', 'Dumbbell Shoulder Press', MuscleGroup.shoulders, Equipment.dumbbell),
  Exercise('arnold_press', 'Arnold Press', MuscleGroup.shoulders, Equipment.dumbbell),
  Exercise('lateral_raise', 'Lateral Raise', MuscleGroup.shoulders, Equipment.dumbbell),
  Exercise('front_raise', 'Front Raise', MuscleGroup.shoulders, Equipment.dumbbell),
  Exercise('rear_delt_fly', 'Rear Delt Fly', MuscleGroup.shoulders, Equipment.dumbbell),
  Exercise('face_pull', 'Face Pull', MuscleGroup.shoulders, Equipment.cable),
  Exercise('kb_press', 'Kettlebell Press', MuscleGroup.shoulders, Equipment.kettlebell),

  // Arms
  Exercise('barbell_curl', 'Barbell Curl', MuscleGroup.arms, Equipment.barbell),
  Exercise('db_curl', 'Dumbbell Curl', MuscleGroup.arms, Equipment.dumbbell),
  Exercise('hammer_curl', 'Hammer Curl', MuscleGroup.arms, Equipment.dumbbell),
  Exercise('preacher_curl', 'Preacher Curl', MuscleGroup.arms, Equipment.machine),
  Exercise('tricep_pushdown', 'Tricep Pushdown', MuscleGroup.arms, Equipment.cable),
  Exercise('skull_crusher', 'Skull Crusher', MuscleGroup.arms, Equipment.barbell),
  Exercise('overhead_tricep_ext', 'Overhead Tricep Extension', MuscleGroup.arms, Equipment.dumbbell),
  Exercise('close_grip_bench', 'Close-Grip Bench Press', MuscleGroup.arms, Equipment.barbell),
  Exercise('tricep_dip', 'Tricep Dip', MuscleGroup.arms, Equipment.bodyweight),

  // Core
  Exercise('plank', 'Plank', MuscleGroup.core, Equipment.bodyweight, timed: true),
  Exercise('crunch', 'Crunch', MuscleGroup.core, Equipment.bodyweight),
  Exercise('hanging_leg_raise', 'Hanging Leg Raise', MuscleGroup.core, Equipment.bodyweight),
  Exercise('cable_crunch', 'Cable Crunch', MuscleGroup.core, Equipment.cable),
  Exercise('ab_wheel', 'Ab Wheel Rollout', MuscleGroup.core, Equipment.bodyweight),
  Exercise('mountain_climber', 'Mountain Climber', MuscleGroup.core, Equipment.bodyweight),
  Exercise('russian_twist', 'Russian Twist', MuscleGroup.core, Equipment.kettlebell),
  Exercise('kb_swing', 'Kettlebell Swing', MuscleGroup.core, Equipment.kettlebell),
];
