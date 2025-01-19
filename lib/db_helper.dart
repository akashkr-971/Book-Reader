import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'book_database.db');
    return openDatabase(path, version: 1, onCreate: (db, version) {
      db.execute('''
        CREATE TABLE books (
          id INTEGER PRIMARY KEY,
          name TEXT,
          path TEXT,
          currentPage INTEGER
        );
      ''');
    });
  }

  static Future<void> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    await db.insert(
      'books',
      book,
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace if the book already exists
    );
  }

  static Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await database;
    return await db.query('books');
  }

  static Future<void> updateBookPage(int id, int page) async {
    final db = await database;
    await db.update(
      'books',
      {'currentPage': page},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteBook(String name) async {
    final db = await database;
    await db.delete(
      'books',
      where: 'name = ?',
      whereArgs: [name],
    );
  }
}

Future<void> clearDatabase() async {
  final db = await DBHelper.database;
  await db.delete('books'); // Delete all rows from the 'books' table
}
