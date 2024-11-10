import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future dbtest() async {
  // The sqflite base factory

  var factory = getIdbFactorySqflite(databaseFactoryFfi);
  // define the store name
  const storeName = 'recordss';

  // open the database
  var db = await factory.open('my_recordss.db', version: 1,
      onUpgradeNeeded: (VersionChangeEvent event) {
    var db = event.database;
    // create the store
    db.createObjectStore(storeName, autoIncrement: true);
  });

  // put some data
  var txn = db.transaction(storeName, 'readwrite');
  var store = txn.objectStore(storeName);
  var key = await store.put({'some': 'newdata'});
  await txn.completed;

  // read some data
  txn = db.transaction(storeName, 'readonly');
  store = txn.objectStore(storeName);
  var value = await store.getObject(key);

  print(value);
  await txn.completed;
}


class UserdataDatabase {
  // Define the store names
  static const String fileManagerStore = 'fileManager';
  static const String deviceListStore = 'deviceList';

  // The sqflite base factory
  final _factory = getIdbFactorySqflite(databaseFactoryFfi);

  // The database instance
  late final Future<dynamic> _db;

  UserdataDatabase() {
    _db = _initDatabase();
  }

  // Initialize the database
  Future<dynamic> _initDatabase() async {
    return await _factory.open('userdata.db', version: 1, onUpgradeNeeded: (VersionChangeEvent event) {
      final db = event.database;
      // Create stores if they don't exist
      db.createObjectStore(fileManagerStore, autoIncrement: true);
      db.createObjectStore(deviceListStore, autoIncrement: true);
    });
  }

  // Get File Manager Data
  Future<Map<String, dynamic>> getFileManagerData() async {
    final db = await _db;
    final txn = db.transaction(fileManagerStore, 'readonly');
    final store = txn.objectStore(fileManagerStore);
    final data = await store.getObject(1); //data is stored at key '1'
    await txn.completed;
    return data ?? {};
  }

  // Save File Manager Data
  Future<void> saveFileManagerData(Map<String, dynamic> data) async {
    final db = await _db;
    final txn = db.transaction(fileManagerStore, 'readwrite');
    final store = txn.objectStore(fileManagerStore);
    await store.put(data, 1); // Save data (auto-generated key)
    await txn.completed;
  }

  // Get Device List Data
  Future<Map<String, dynamic>> getDeviceListData() async {
    final db = await _db;
    final txn = db.transaction(deviceListStore, 'readonly');
    final store = txn.objectStore(deviceListStore);
    final data = await store.getObject(1); //data is stored at key '1'
    await txn.completed;
    return data ?? {};
  }

  // Save Device List Data
  Future<void> saveDeviceListData(Map<String, dynamic> data) async {
    final db = await _db;
    final txn = db.transaction(deviceListStore, 'readwrite');
    final store = txn.objectStore(deviceListStore);
    await store.clear(); // This deletes all data in the store
    await store.put(data, 1); // Save the new data
    await txn.completed;
  }

}