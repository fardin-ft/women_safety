import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'guardian_care.db');
    return await openDatabase(
      path,
      version: 8,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        phone TEXT,
        mascot TEXT
      )
    ''');
    await _createPersonalInfoTable(db);
    await _createCycleInfoTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPersonalInfoTable(db);
    }
    if (oldVersion < 3) {
      var columns = await db.rawQuery('PRAGMA table_info(users)');
      bool hasPhone = columns.any((c) => c['name'] == 'phone');
      if (!hasPhone) {
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        DELETE FROM personal_info 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM personal_info 
          GROUP BY user_id
        )
      ''');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_personal_info_user_id ON personal_info (user_id)');
    }
    if (oldVersion < 6) {
      await _createPeriodsTable(db);
    }
    if (oldVersion < 7) {
      var columns = await db.rawQuery('PRAGMA table_info(users)');
      bool hasMascot = columns.any((c) => c['name'] == 'mascot');
      if (!hasMascot) {
        await db.execute('ALTER TABLE users ADD COLUMN mascot TEXT');
      }
    }
    if (oldVersion < 8) {
      // Handle schema changes for personal_info (removing old columns and adding CHECK constraint)
      await db.execute('ALTER TABLE personal_info RENAME TO personal_info_old');
      await _createPersonalInfoTable(db);
      
      // Get columns from old table to safely copy data
      var oldColumnsInfo = await db.rawQuery('PRAGMA table_info(personal_info_old)');
      var oldColumnNames = oldColumnsInfo.map((c) => c['name']).toList();
      
      String columnsToSelect = [
        'user_id',
        oldColumnNames.contains('blood_group') ? 'blood_group' : "''",
        oldColumnNames.contains('weight') ? 'weight' : '0.0',
        oldColumnNames.contains('height') ? 'height' : '0.0',
        oldColumnNames.contains('emergency_number1') ? 'emergency_number1' : "''",
        oldColumnNames.contains('emergency_number2') ? 'emergency_number2' : "''",
      ].join(', ');

      await db.execute('''
        INSERT INTO personal_info (user_id, blood_group, weight, height, emergency_number1, emergency_number2)
        SELECT $columnsToSelect FROM personal_info_old
      ''');
      await db.execute('DROP TABLE personal_info_old');
    }
  }

  Future<void> _createPeriodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        start_date TEXT,
        end_date TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPersonalInfoTable(Database db) async {
    await db.execute('''
      CREATE TABLE personal_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        blood_group TEXT CHECK(blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', '', NULL)),
        weight REAL,
        height REAL,
        emergency_number1 TEXT,
        emergency_number2 TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createCycleInfoTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cycle_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE,
        last_period_date TEXT,
        cycle_length INTEGER,
        period_length INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> saveCycleInfo(Map<String, dynamic> info) async {
    final db = await database;
    return await db.insert('cycle_info', info, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCycleInfo(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'cycle_info',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> savePeriod(Map<String, dynamic> period) async {
    final db = await database;
    return await db.insert('periods', period);
  }

  Future<List<Map<String, dynamic>>> getPeriods(int userId) async {
    final db = await database;
    return await db.query(
      'periods',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_date DESC',
    );
  }

  Future<int> savePersonalInfo(Map<String, dynamic> info) async {
    final db = await database;
    return await db.insert(
      'personal_info',
      info,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getPersonalInfo(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'personal_info',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateProfile(int userId, String name, String email, String phone) async {
    final db = await database;
    return await db.update(
      'users',
      {'name': name, 'email': email, 'phone': phone},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateMascot(int userId, String mascot) async {
    final db = await database;
    return await db.update(
      'users',
      {'mascot': mascot},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> registerUser(String name, String email, String password, {String? phone}) async {
    final db = await database;
    try {
      return await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });
    } catch (e) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
