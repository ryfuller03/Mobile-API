import 'package:flutter/material.dart';
import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:igdb/igdb.dart';

class Game {
  final int id;
  final String title;
  final int rating;
  final String reviewText;

  const Game(
      {required this.id,
      required this.title,
      required this.rating,
      required this.reviewText});

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'rating': rating,
      'reviewText': reviewText
    };
  }

  @override
  String toString() {
    return 'Game{id: $id, title: $title, rating: $rating, reviewText: $reviewText}';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = IGDBClient(
      'rmgcgjxsloru41ei4npaknt3km5w7k', 'dfvmxuxivi7g90vw9qprkwz5njzjnt');
  const igdbRequestParameters = IGDBRequestParameters(
      fields: ["name", "cover"], search: "Halo", limit: 3);
  final jsonInfo = await client.gameJson(
    igdbRequestParameters,
  );
  // const IGDBRequestParameters2 = IGDBRequestParameters(fields: "image_id")

  final database = openDatabase(join(await getDatabasesPath(), 'user_logs.db'),
      onCreate: (db, version) {
    return db.execute(
        'CREATE TABLE games(id INTEGER PRIMARY KEY, title TEXT, rating INTEGER, reviewText TEXT)');
  }, version: 1);

  runApp(MyApp(
    database: database,
    json: jsonInfo,
  ));
}

class MyApp extends StatelessWidget {
  final Future<Database> database;
  final dynamic json;

  const MyApp({super.key, required this.database, required this.json});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalag',
      theme: ThemeData(
        colorScheme:
            const ColorScheme.dark(primary: Color.fromARGB(255, 53, 122, 55)),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Catalag', database: database, json: json),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Future<Database> database;
  final dynamic json;

  const MyHomePage(
      {super.key,
      required this.title,
      required this.database,
      required this.json});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 1;

  Future<void> _insertGame(Game game) async {
    final db = await widget.database;

    await db.insert(
      'games',
      game.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Game>> _games() async {
    final db = await widget.database;

    final List<Map<String, Object?>> gameMaps = await db.query('games');

    return [
      for (final {
            'id': id as int,
            'title': title as String,
            'rating': rating as int,
            'reviewText': reviewText as String,
          } in gameMaps)
        Game(id: id, title: title, rating: rating, reviewText: reviewText)
    ];
  }

  Future<void> _updateGame(Game game) async {
    final db = await widget.database;

    await db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  Future<void> deleteGame(int id) async {
    final db = await widget.database;

    await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String jsonStuff = widget.json.toString();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title:
            Text(widget.title, style: const TextStyle(fontFamily: 'SpaceMono')),
      ),
      body: Center(
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              jsonStuff,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: const Color.fromARGB(255, 53, 122, 55),
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
                icon: Icon(Icons.search),
                label: "Search",
                selectedIcon: Icon(Icons.search_outlined)),
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: "Games",
                selectedIcon: Icon(Icons.home)),
            NavigationDestination(
                icon: Icon(Icons.list),
                label: "Lists",
                selectedIcon: Icon(Icons.list_outlined))
          ]),
    );
  }
}
