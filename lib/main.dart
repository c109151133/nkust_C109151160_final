import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'diary_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE entries(id INTEGER PRIMARY KEY AUTOINCREMENT, entry TEXT)',
      );
    },
    version: 1,
  );

  runApp(DiaryApp(database: database));
}

class DiaryApp extends StatelessWidget {
  final Future<Database> database;

  DiaryApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DiaryHomePage(database: database),
    );
  }
}

class DiaryHomePage extends StatefulWidget {
  final Future<Database> database;

  DiaryHomePage({required this.database});

  @override
  _DiaryHomePageState createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  List<Map<String, dynamic>> entries = [];

  void addEntry(String entry) async {
    final db = await widget.database;
    await db.insert(
      'entries',
      {'entry': entry},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    refreshEntries();
  }

  void deleteEntry(int id) async {
    final db = await widget.database;
    await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    refreshEntries();
  }

  void refreshEntries() async {
    final db = await widget.database;
    final List<Map<String, dynamic>> maps = await db.query('entries');
    setState(() {
      entries = maps;
    });
  }

  @override
  void initState() {
    super.initState();
    refreshEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Diary'),
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(entries[index]['entry']),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => deleteEntry(entries[index]['id']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEntryDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? newEntry;
        return AlertDialog(
          title: Text('Add New Entry'),
          content: TextField(
            onChanged: (value) {
              newEntry = value;
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (newEntry != null) {
                  addEntry(newEntry!);
                }
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
