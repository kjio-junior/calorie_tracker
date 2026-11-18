import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Single on-device SQLite database. All tables are created up front so the
/// schema stays stable while later phases add features.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'calorie_tracker.db';
  static const _version = 5;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  /// Full path of the database file (used by backup/restore later).
  Future<String> get path async =>
      p.join(await getDatabasesPath(), _fileName);

  Future<Database> _open() async {
    return openDatabase(
      await path,
      version: _version,
      onCreate: (db, version) async {
        final b = db.batch();

        b.execute('''
          CREATE TABLE weight_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            weight_kg REAL NOT NULL,
            created_at INTEGER NOT NULL
          )''');

        // Targets in force on each day, so history keeps the target you had
        // at the time even after your weight (and targets) change.
        b.execute('''
          CREATE TABLE daily_targets (
            date TEXT PRIMARY KEY,
            calorie_target INTEGER NOT NULL,
            protein_target INTEGER,
            bmr REAL NOT NULL,
            tdee REAL NOT NULL,
            weight_kg REAL NOT NULL
          )''');

        b.execute('''
          CREATE TABLE saved_foods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            brand TEXT,
            source TEXT NOT NULL,
            off_code TEXT UNIQUE,
            serving_g REAL,
            serving_desc TEXT,
            kcal_per_100g REAL,
            protein_per_100g REAL,
            kcal_per_serving REAL,
            protein_per_serving REAL,
            carbs_per_100g REAL,
            fat_per_100g REAL,
            carbs_per_serving REAL,
            fat_per_serving REAL,
            use_count INTEGER NOT NULL DEFAULT 0,
            last_used INTEGER,
            created_at INTEGER NOT NULL
          )''');

        b.execute('''
          CREATE TABLE food_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            meal TEXT NOT NULL,
            name TEXT NOT NULL,
            serving_desc TEXT,
            quantity REAL NOT NULL DEFAULT 1,
            calories REAL NOT NULL,
            protein REAL NOT NULL DEFAULT 0,
            carbs REAL NOT NULL DEFAULT 0,
            fat REAL NOT NULL DEFAULT 0,
            saved_food_id INTEGER,
            created_at INTEGER NOT NULL
          )''');

        // external_id lets a future Strava sync upsert without schema changes.
        b.execute('''
          CREATE TABLE cardio_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            activity_type TEXT NOT NULL,
            duration_min REAL NOT NULL,
            distance_km REAL,
            calories_burned REAL,
            source TEXT NOT NULL DEFAULT 'manual',
            external_id TEXT UNIQUE,
            created_at INTEGER NOT NULL
          )''');

        b.execute('''
          CREATE TABLE workout_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            session_id INTEGER,
            exercise_id TEXT NOT NULL,
            exercise_name TEXT NOT NULL,
            muscle_group TEXT NOT NULL,
            set_index INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            weight_kg REAL NOT NULL,
            est_calories REAL,
            created_at INTEGER NOT NULL
          )''');

        b.execute('''
          CREATE TABLE ai_summaries (
            date TEXT PRIMARY KEY,
            summary TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''');

        b.execute('''
          CREATE TABLE workout_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            name TEXT,
            duration_min REAL,
            intensity TEXT,
            est_calories REAL,
            created_at INTEGER NOT NULL
          )''');
        b.execute('CREATE INDEX idx_workout_sessions_date ON workout_sessions(date)');
        b.execute('''
          CREATE TABLE cheat_days (
            date TEXT PRIMARY KEY,
            created_at INTEGER NOT NULL
          )''');
        b.execute('CREATE INDEX idx_food_logs_date ON food_logs(date)');
        b.execute('CREATE INDEX idx_cardio_logs_date ON cardio_logs(date)');
        b.execute('CREATE INDEX idx_workout_logs_date ON workout_logs(date)');

        await b.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE saved_foods ADD COLUMN serving_desc TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE workout_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              name TEXT,
              duration_min REAL,
              intensity TEXT,
              est_calories REAL,
              created_at INTEGER NOT NULL
            )''');
          await db.execute('ALTER TABLE workout_logs ADD COLUMN session_id INTEGER');
          await db.execute('CREATE INDEX idx_workout_sessions_date ON workout_sessions(date)');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE cheat_days (
              date TEXT PRIMARY KEY,
              created_at INTEGER NOT NULL
            )''');
        }
        if (oldVersion < 5) {
          // Carbohydrate and fat tracking.
          await db.execute('ALTER TABLE food_logs ADD COLUMN carbs REAL NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE food_logs ADD COLUMN fat REAL NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE saved_foods ADD COLUMN carbs_per_100g REAL');
          await db.execute('ALTER TABLE saved_foods ADD COLUMN fat_per_100g REAL');
          await db.execute('ALTER TABLE saved_foods ADD COLUMN carbs_per_serving REAL');
          await db.execute('ALTER TABLE saved_foods ADD COLUMN fat_per_serving REAL');
        }
      },
    );
  }
}
