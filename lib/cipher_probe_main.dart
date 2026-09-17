import 'dart:io';
import 'dart:ui';

import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

/// One-shot: create Documents/cipher_probe.db with the app ENCRYPTION_KEY
/// using this build's sqflite_sqlcipher, then idle so the file can be pulled.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final key = dotenv.env[AssetsConstants.dbPasswordKey] ?? '';
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'cipher_probe.db');
  try {
    if (await File(path).exists()) await File(path).delete();
  } catch (_) {}
  debugPrint(
      'CIPHER_PROBE start path=$path keyLen=${key.length} keyEmpty=${key.isEmpty}');
  final db = await sqlcipher.openDatabase(path, password: key);
  await db.execute(
      'CREATE TABLE IF NOT EXISTS probe (id INTEGER PRIMARY KEY, v TEXT)');
  await db.insert('probe', {'v': 'ok'});
  final n = await db.rawQuery('SELECT COUNT(*) AS c FROM probe');
  await db.close();
  final header = await File(path).open();
  final bytes = await header.read(16);
  await header.close();
  final ascii = String.fromCharCodes(bytes);
  debugPrint(
      'CIPHER_PROBE wrote bytes=${await File(path).length()} headerHex=${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} headerAscii=$ascii');
  debugPrint('CIPHER_PROBE rows=$n');
  runApp(const ColoredBox(color: Color(0xFF000000)));
}
