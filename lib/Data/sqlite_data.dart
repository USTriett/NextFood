import 'dart:io';
import 'package:next_food/DAO/category_dao.dart';
import 'package:next_food/DAO/food_dao.dart';
import 'package:next_food/DAO/history_dao.dart';
import 'package:next_food/DAO/question_dao.dart';
import 'package:next_food/Data/data_manager.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../Values/constants.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
}

class SqliteData {
  static Database? _database;
  static Future<Database?> get database async {
    if (_database != null) {
      print("un null database");
      return _database;
    }

    // if _database is null we instantiate it
    _database = await initDB();
    print("datapath: ${_database?.path}");
    return _database;
  }

  static Future<void> deleteDatabaseFile() async {
    // Lấy thư mục lưu trữ ứng dụng
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'NextFood.db');

    // Xóa cơ sở dữ liệu SQLite

    await deleteDatabase(dbPath);
    _database = null;
  }

  static initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "NextFood.db");
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE QUESTIONS ("
          "id TEXT PRIMARY KEY,"
          "options TEXT,"
          "question TEXT"
          ")");
      await db.execute("CREATE TABLE CATEGORIES ("
          "categoryID TEXT PRIMARY KEY,"
          "categoryName TEXT,"
          "imageURL TEXT,"
          "listFoodId TEXT"
          ")");
      await db.execute("CREATE TABLE FOODS ("
          "id TEXT PRIMARY KEY,"
          "description TEXT,"
          "image TEXT,"
          "match_count INTEGER,"
          "name TEXT"
          ")");
      // print("food created");
      await db.execute("CREATE TABLE HISTORY ("
          "foodID TEXT,"
          "foodImage TEXT,"
          "foodName TEXT,"
          "restaurantAddress TEXT,"
          "restaurantID TEXT,"
          "restaurantName TEXT,"
          "timeStamp DATETIME,"
          "PRIMARY KEY (foodID, restaurantID, timeStamp)"
          ")");

      // await db.execute('''
      //   CREATE TABLE HISTORY(
      //     id INTEGER PRIMARY KEY,
      //     userId INTEGER,
      //     description TEXT,
      //     FOREIGN KEY (userId) REFERENCES USER(id)
      //   )
      // ''');
    });
  }

  static Future<void> insertAllData() async {
    Database? db = await database;
    List<HistoryDAO> histories = await DataManager.getHistory();
    // print(histories.length);
    for (HistoryDAO h in histories) {
      await db?.insert("HISTORY", h.toJson());
      // print(h.toJson());
    }
    List<FoodDAO> foods = await DataManager.getAllFoods();
    for (FoodDAO f in foods) {
      await db?.insert("FOODS", f.toJson());
      // print(f.toJson());
    }
    List<CategoryDAO> categories = await DataManager.getAllCategories();
    for (CategoryDAO f in categories) {
      await db?.insert("CATEGORIES", f.toJson());
      // print(f.toJson());
    }

    List<QuestionDAO> questions = await DataManager.getAllQuestion();
    for (QuestionDAO q in questions) {
      await db?.insert("QUESTIONS", q.toJson());
      // print(q.toJson());
    }
  }

  static Future<void> updateHistoryData(HistoryDAO history) async {
    Database? db = await database;
    await db?.insert("HISTORY", history.toJson());
    DAO.history.add(history);
  }

  static Future<FoodDAO> getFoodByName(String name) async {
    final db = await database;
    var res = await db?.query("FOODS", where: "name = ?", whereArgs: [name]);
    FoodDAO food = FoodDAO.fromMap(res!.first);
    return food;
  }

  static Future<List<FoodDAO>> getAllFoods() async {
    final db = await database;
    var res = await db?.query("FOODS");
    if (res == null) return [];
    List<FoodDAO> foods =
        res!.isNotEmpty ? res.map((c) => FoodDAO.fromMap(c)).toList() : [];
    return foods;
  }

  static Future<List<HistoryDAO>> getHistory() async {
    final db = await database;
    var res = await db?.query("HISTORY");
    List<HistoryDAO> his =
        res!.isNotEmpty ? res.map((c) => HistoryDAO.fromMap(c)).toList() : [];
    return his;
  }

  static Future<List<QuestionDAO>> getAllQuestions() async {
    final db = await database;
    var res = await db?.query("QUESTIONS");
    List<QuestionDAO> his =
        res!.isNotEmpty ? res.map((c) => QuestionDAO.fromMap(c)).toList() : [];
    return his;
  }

  static Future<List<CategoryDAO>> getAllCategories() async {
    final db = await database;
    var res = await db?.query("CATEGORIES");
    List<CategoryDAO> cate =
        res!.isNotEmpty ? res.map((c) => CategoryDAO.fromMap(c)).toList() : [];
    return cate;
  }

  static Future<void> loadAllData() async {
    DAO.foods = await getAllFoods();
    DAO.list = await getAllQuestions();
    DAO.history = await getHistory();
    DAO.categories = await getAllCategories();
  }
}