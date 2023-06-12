import 'package:sk_login_sofia/interfaces/IRidesService.dart';
import 'package:sk_login_sofia/models/Ride.dart';
import 'package:sk_login_sofia/models/RideSearchParameters.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class RidesService implements IRidesService {
  static const String databaseName = 'rides.db';
  static const int databaseVersion = 1;

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);
    return openDatabase(path, version: databaseVersion,
        onCreate: (db, version) async {
      await db.execute('''
          CREATE TABLE rides (
            id INTEGER PRIMARY KEY,
            elevatorId TEXT,
            start INTEGER,
            startingFloor TEXT,
            targetFloor TEXT,
            username TEXT
          )
        ''');
    });
  }

  @override
  Future<Ride> addAsync(Ride ride) async {
    final db = await _openDatabase();
    ride.id = await db.insert('rides', ride.toMap());
    return ride;
  }

  @override
  Future<List<Ride>> searchAsync(RideSearchParameters parameters) async {
    final db = await _openDatabase();
    final queryBuilder = StringBuffer('SELECT * FROM rides WHERE 1=1');

    if (parameters.elevatorId != null && parameters.elevatorId!.isNotEmpty) {
      queryBuilder.write(' AND elevatorId = "${parameters.elevatorId}"');
    }

    if (parameters.from != null) {
      final fromTimestamp = parameters.from!.millisecondsSinceEpoch;
      queryBuilder.write(' AND start >= $fromTimestamp');
    }

    if (parameters.to != null) {
      final toTimestamp = parameters.to!.millisecondsSinceEpoch;
      queryBuilder.write(' AND start <= $toTimestamp');
    }

    if (parameters.username != null && parameters.username!.isNotEmpty) {
      queryBuilder.write(' AND username = "${parameters.username}"');
    }

    if (parameters.startingFloor != null &&
        parameters.startingFloor!.isNotEmpty) {
      queryBuilder.write(' AND startingFloor = "${parameters.startingFloor}"');
    }

    if (parameters.targetFloor != null && parameters.targetFloor!.isNotEmpty) {
      queryBuilder.write(' AND targetFloor = "${parameters.targetFloor}"');
    }

    queryBuilder.write(' ORDER BY start DESC');

    if (parameters.length != -1) {
      queryBuilder.write(' LIMIT ${parameters.length}');
    }

    final queryResult = await db.rawQuery(queryBuilder.toString());
    final rides = queryResult.map((row) => Ride.fromMap(row)).toList();
    return rides;
  }
}
