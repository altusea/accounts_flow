import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = 'accounts_flow.db';
  static const int _databaseVersion = 1;

  // 单例模式
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 创建账户表
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        balance REAL NOT NULL,
        color INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // 创建余额历史表
    await db.execute('''
      CREATE TABLE balance_history (
        id TEXT PRIMARY KEY,
        accountId TEXT NOT NULL,
        balance REAL NOT NULL,
        recordDate INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');
  }

  // 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}