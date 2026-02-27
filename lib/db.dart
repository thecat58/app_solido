import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final pathDB = await getDatabasesPath();
    final path = join(pathDB, "pedidos.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pedidos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            valor TEXT,
            detalle TEXT,
            fechaEntrega TEXT,
            color TEXT,
            imagen TEXT,
            colorCard TEXT
          )
        ''');
      },
    );
  }
}
