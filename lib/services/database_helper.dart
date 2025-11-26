import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = 'accounts_flow.db';
  static const int _databaseVersion = 3;

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
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 创建账户表
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
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

    // 创建账户顺序表
    await db.execute('''
      CREATE TABLE account_order (
        accountId TEXT PRIMARY KEY,
        position INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 从版本1升级到版本2：添加账户顺序表
      await db.execute('''
        CREATE TABLE account_order (
          accountId TEXT PRIMARY KEY,
          position INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // 从版本2升级到版本3：移除账户表的 balance 字段
      // 创建临时表
      await db.execute('''
        CREATE TABLE accounts_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type INTEGER NOT NULL,
          color INTEGER NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');

      // 复制数据（排除 balance 字段）
      await db.execute('''
        INSERT INTO accounts_new (id, name, type, color, createdAt)
        SELECT id, name, type, color, createdAt FROM accounts
      ''');

      // 删除旧表
      await db.execute('DROP TABLE accounts');

      // 重命名新表
      await db.execute('ALTER TABLE accounts_new RENAME TO accounts');
    }
  }

  // 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}