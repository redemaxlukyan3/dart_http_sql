import 'package:dart_application_1/dart_application_1.dart' as dart_application_1;
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';


void main(List<String> arguments) async {

  // Http request
  final url = Uri.https('api.genderize.io', '/',{'name': 'oleg'},);
  final response = await http.get(url);

  // Decode data from JSON
  final jsonResponse = convert.jsonDecode(response.body);
  print(jsonResponse);
  final Root root = Root.fromJson(jsonResponse);

  // Create database
  print('Using sqlite3 ${sqlite3.version}');
  final db = sqlite3.open("database.db");

  // Create table
  db.execute('''
    CREATE TABLE IF NOT EXISTS NAMES (
      count INT,
      gender TEXT,
      name TEXT NOT NULL PRIMARY KEY UNIQUE ON CONFLICT REPLACE,
      probability REAL
    );
  ''');

  // Insert data
  final stmt = db.prepare('INSERT OR REPLACE INTO NAMES (count, gender, name, probability) VALUES (?, ?, ?, ?)');
  stmt.execute([root.count, root.gender, root.name, root.probability]);
  stmt.dispose();

  // Read data
  final ResultSet resultSet =
      db.select('SELECT * FROM NAMES');

  // Write to txt
  File file = File("note1.txt");
  for (final Row row in resultSet) {
    await file.writeAsString('${row['count']}\t${row['gender']}\t${row['name']}\t${row['probability']}\r\n', mode: FileMode.append);
  }

  db.createFunction(
    functionName: 'dart_version',
    argumentCount: const AllowedArgumentCount(0),
    function: (args) => Platform.version,
  );
  print(db.select('SELECT dart_version()'));
  
  db.dispose();

}

class Root {
  int? count;
  String? gender;
  String? name;
  double? probability;

  Root({this.count, this.gender, this.name, this.probability});

  Root.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    gender = json['gender'];
    name = json['name'];
    probability = json['probability'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    data['gender'] = this.gender;
    data['name'] = this.name;
    data['probability'] = this.probability;
    return data;
  }
}