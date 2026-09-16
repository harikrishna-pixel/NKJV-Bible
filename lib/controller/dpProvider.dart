import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as plain;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:biblebookapp/Model/dailyVersesMainListModel.dart';
import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';

import '../Model/bookMarkModel.dart';
import '../Model/highLightContentModal.dart';
import '../Model/saveImagesModel.dart';
import '../Model/saveNotesModel.dart';
import '../Model/verseBookContentModel.dart';

/// Single source of truth: same file + directory as [DBHelper.initDatabase].
/// Prevents "latest → latest" opening a different path than migration code.
class BibleEncryptedDbPaths {
  static const String fileName = 'bible_enc.db';

  static Future<String> absolutePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, fileName);
  }
}

class DBHelper {
  // Can be opened either as encrypted (sqlcipher) or as plain sqlite depending
  // on what exists on disk and whether password/encryption format matches.
  // Keep dynamic so we can still query in fallback scenarios.
  static dynamic _db;

  /// Cold start (Splash): drop any in-memory connection so we always open
  /// the on-disk `bible_enc.db`. Fixes stale singleton after reinstall/overwrite
  /// when prefs were restored but the DB file is new or empty.
  static Future<void> resetStaticDatabaseConnection() async {
    if (_db != null) {
      try {
        await _db!.close();
      } catch (_) {}
      _db = null;
    }
  }

  static Future<dynamic>? _dbOpening;

  Future<dynamic> get db async {
    if (_db != null) {
      try {
        await _db!.rawQuery('SELECT 1');
        return _db;
      } catch (_) {
        try {
          await _db!.close();
        } catch (_) {}
        _db = null;
      }
    }
    return _dbOpening ??= () async {
      try {
        _db = await initDatabase();
        return _db;
      } finally {
        _dbOpening = null;
      }
    }();
  }

  /// 128 open path, with one safety: if the file header is plain SQLite,
  /// open it as plain. SQLCipher+password on a plaintext file does not persist
  /// library inserts. Encrypted files still use ENCRYPTION_KEY first.
  static Future<dynamic> openLike128(
    String path, {
    String? password,
    int? version,
    bool singleInstance = true,
    Future<void> Function(dynamic db, int version)? onCreate,
    Future<void> Function(dynamic db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    if (await File(path).exists() && await _fileHasPlainSqliteHeader(path)) {
      return await plain.openDatabase(
        path,
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        singleInstance: singleInstance,
      );
    }
    if (password != null && password.isNotEmpty) {
      try {
        return await sqlcipher.openDatabase(
          path,
          version: version,
          password: password,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
          singleInstance: singleInstance,
        );
      } catch (e) {
        debugPrint('DBHelper.initDatabase encrypted open failed: $e');
      }
    }
    try {
      debugPrint('DBHelper.openLike128 plain fallback $path');
      return await plain.openDatabase(
        path,
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        singleInstance: singleInstance,
      );
    } catch (e) {
      debugPrint('DBHelper.openLike128 plain fallback failed: $e');
    }
    if (await File(path).exists() && !await _fileHasPlainSqliteHeader(path)) {
      throw StateError('SQLCipher open failed for $path');
    }
    return await plain.openDatabase(
      path,
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      singleInstance: singleInstance,
    );
  }

  /// Keep the 128 open path first. Only if that fails on an existing encrypted
  /// file, use [openSqlCipherDatabase] (SQLCipher 3/4 + key candidates).
  /// Existing files are opened without onCreate so a false SQLCipher 4 open
  /// cannot wipe 101/128 library tables.
  static Future<dynamic> openLiveOrRecoverEncrypted(
    String path, {
    String? password,
    int? version,
    bool singleInstance = true,
    Future<void> Function(dynamic db, int version)? onCreate,
    Future<void> Function(dynamic db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    final exists = await File(path).exists();
    try {
      final db = await openLike128(
        path,
        password: password,
        version: exists ? null : version,
        singleInstance: singleInstance,
        onCreate: exists ? null : onCreate,
        onUpgrade: exists ? null : onUpgrade,
      );
      if (exists && !await _openedDbHasUserTables(db, path)) {
        try {
          await db.close();
        } catch (_) {}
        throw StateError('openLike128 false-open (no tables) for $path');
      }
      return db;
    } catch (e) {
      debugPrint('DBHelper.openLike128 failed: $e');
      if (!exists || await _fileHasPlainSqliteHeader(path)) {
        rethrow;
      }
      debugPrint('DBHelper trying SQLCipher recovery open for $path');
      return await openSqlCipherDatabase(
        path,
        password: password,
      );
    }
  }

  /// Large existing files that open with zero app tables are a false SQLCipher
  /// open (wrong compat/key). Treat as failure so we do not keep an empty DB.
  static Future<bool> _openedDbHasUserTables(dynamic db, String path) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
      );
      if (tables.isNotEmpty) return true;
    } catch (_) {
      return false;
    }
    try {
      if (await File(path).length() >= 4096) return false;
    } catch (_) {}
    return true;
  }

  static Future<void> _copySqliteSidecars(String fromPath, String toPath) async {
    for (final suffix in <String>['-wal', '-shm']) {
      try {
        final src = File('$fromPath$suffix');
        if (await src.exists()) {
          await src.copy('$toPath$suffix');
        }
      } catch (e) {
        debugPrint('DBHelper sidecar copy $suffix failed: $e');
      }
    }
  }

  static sqlcipher.Database? _cipherDefaultHolder;

  /// Keep a live SQLCipher connection so cipher_default_* applies to the next
  /// open. :memory: pragmas do not affect other connections on iOS, so 128
  /// SQLCipher 3 files were opened as SQLCipher 4 ("file is not a database").
  static Future<void> _setSqlCipherDefaultCompat(int? compatibility) async {
    try {
      await _cipherDefaultHolder?.close();
    } catch (_) {}
    _cipherDefaultHolder = null;
    final tmpDir = await getTemporaryDirectory();
    final tmp = p.join(tmpDir.path, 'cipher_defaults_${compatibility ?? 0}.db');
    try {
      await File(tmp).delete();
    } catch (_) {}
    final holder = await sqlcipher.openDatabase(
      tmp,
      password: 'compat-holder',
      singleInstance: false,
    );
    _cipherDefaultHolder = holder;
    if (compatibility != null) {
      await _runPragma(
          holder, 'PRAGMA cipher_default_compatibility = $compatibility');
    }
    if (compatibility != null && compatibility <= 3) {
      await _runPragma(holder, 'PRAGMA cipher_default_kdf_iter = 64000');
      await _runPragma(holder, 'PRAGMA cipher_default_page_size = 1024');
    }
  }

  /// Open a 128 on-disk file without creating a new empty DB.
  /// 128 used ENCRYPTION_KEY via SQLCipher, then plain sqlite.
  static Future<dynamic?> tryOpenExisting128File(
    String path, {
    String? password,
    bool singleInstance = false,
  }) async {
    if (!await File(path).exists()) return null;

    if (await _fileHasPlainSqliteHeader(path)) {
      debugPrint('tryOpenExisting128File plain sqlite $path');
      return await plain.openDatabase(path, singleInstance: true);
    }

    final keys = <String>[];
    final seen = <String>{};
    void addKey(String? key) {
      if (key == null || key.isEmpty) return;
      if (seen.add(key)) keys.add(key);
    }

    addKey(encryptionPassword(keepRawWhitespace: true));
    addKey(password);
    addKey(encryptionPassword());
    for (final extra in encryptionPasswordCandidates()) {
      addKey(extra);
    }

    for (final compat in <int?>[null, 4, 3, 2, 1]) {
      try {
        await _setSqlCipherDefaultCompat(compat);
      } catch (e) {
        debugPrint('tryOpenExisting128File compat setup $compat: $e');
      }
      for (final key in keys) {
        try {
          final db = await sqlcipher.openDatabase(
            path,
            password: key,
            singleInstance: singleInstance,
          );
          if (!await _openedDbHasUserTables(db, path)) {
            debugPrint(
                'tryOpenExisting128File false-open compat=$compat keyLen=${key.length}');
            try {
              await db.close();
            } catch (_) {}
            continue;
          }
          debugPrint(
              'tryOpenExisting128File ok compat=$compat keyLen=${key.length}');
          return db;
        } catch (e) {
          debugPrint(
              'tryOpenExisting128File fail compat=$compat keyLen=${key.length}: $e');
        }
      }
    }
    try {
      debugPrint('tryOpenExisting128File plain fallback $path');
      final db = await plain.openDatabase(path, singleInstance: singleInstance);
      if (!await _openedDbHasUserTables(db, path)) {
        try {
          await db.close();
        } catch (_) {}
        return null;
      }
      debugPrint('tryOpenExisting128File ok plain fallback');
      return db;
    } catch (e) {
      debugPrint('tryOpenExisting128File plain fallback fail: $e');
    }
    return null;
  }

  static Future<void> _keepPreUpgradeCopy(String path) async {
    try {
      final file = File(path);
      if (!await file.exists() || await file.length() < 4096) return;
      final keep = '$path.pre-upgrade.bak';
      if (await File(keep).exists()) return;
      await file.copy(keep);
      await _copySqliteSidecars(path, keep);
      debugPrint('DBHelper saved pre-upgrade copy $keep');
    } catch (e) {
      debugPrint('DBHelper pre-upgrade copy failed: $e');
    }
  }

  /// Additive schema only. Safe on 101/128 files that already have tables.
  static Future<void> ensureCurrentSchema(dynamic db) async {
    Future<void> tryExec(String sql) async {
      try {
        await db.execute(sql);
      } catch (e) {
        debugPrint('ensureCurrentSchema: $e');
      }
    }

    await tryExec(
        'CREATE TABLE IF NOT EXISTS "calendar" (id INTEGER PRIMARY KEY AUTOINCREMENT,"title" TEXT,"date" DATETIME)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "verse" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER,"content" TEXT,"is_read" TEXT,"is_bookmarked" TEXT,"is_underlined" TEXT,"is_highlighted" TEXT,"is_noted" TEXT)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "bookmark" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR,"bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "save_notes" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR,"book_name" VARCHAR, "notes" VARCHAR, "plaincontent" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "highlight" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plain_content" VARCHAR, verse_id VARCHAR, "book_name" VARCHAR,"color" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "underline" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR, "bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "book" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER,"title" TEXT,"short_title" TEXT,"chapter_count" INTEGER,"read_per" TEXT)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "save_images" (id INTEGER PRIMARY KEY AUTOINCREMENT,"image_path" TEXT)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "dailyVersesMainList" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT)');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "dailyVerses" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
    await tryExec(
        'CREATE TABLE IF NOT EXISTS "dailyVersesnew" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
    await tryExec('ALTER TABLE bookmark ADD COLUMN plaincontent VARCHAR');
    await tryExec('ALTER TABLE save_notes ADD COLUMN plaincontent VARCHAR');
    await tryExec('ALTER TABLE highlight ADD COLUMN plain_content VARCHAR');
    await tryExec('ALTER TABLE highlight ADD COLUMN verse_id VARCHAR');
    try {
      await db.execute('PRAGMA user_version = 3');
    } catch (_) {}
  }

  /// SQLCipher key from `.env`. Always trim: a trailing space is a different key
  /// (`file is not a database`). 128 used the key with no trailing space.
  static String? encryptionPassword({bool keepRawWhitespace = false}) {
    final raw = dotenv.env[AssetsConstants.dbPasswordKey];
    if (raw == null) return null;
    return keepRawWhitespace ? raw : raw.trim();
  }

  /// Drop null `id` so AUTOINCREMENT can assign. Null id was swallowed by
  /// insert catch blocks, so "Marked Successfully" showed with an empty library.
  static Map<String, Object?> _libraryInsertValues(Map<String, dynamic> raw) {
    final map = <String, Object?>{};
    raw.forEach((key, value) {
      if (value != null) map[key] = value;
    });
    map.remove('id');
    return map;
  }

  /// Raw `.env` ENCRYPTION_KEY first (same as 128). Trimmed and hashed forms
  /// are fallbacks only.
  static List<String> encryptionPasswordCandidates() {
    final raw = dotenv.env[AssetsConstants.dbPasswordKey];
    if (raw == null || raw.isEmpty) return const [];
    final trimmed = raw.trim();
    if (trimmed.isEmpty && raw.isEmpty) return const [];
    final candidates = <String>[];
    if (raw.isNotEmpty) candidates.add(raw);
    if (trimmed.isNotEmpty && trimmed != raw) candidates.add(trimmed);

    void addRawHexKey(String hex) {
      if (hex.isEmpty) return;
      final wrapped = "x'$hex'";
      if (!candidates.contains(hex)) candidates.add(hex);
      if (!candidates.contains(wrapped)) candidates.add(wrapped);
    }

    final forHash = raw.isNotEmpty ? raw : trimmed;
    try {
      addRawHexKey(sha256.convert(utf8.encode(forHash)).toString());
    } catch (_) {}
    try {
      addRawHexKey(md5.convert(utf8.encode(forHash)).toString());
    } catch (_) {}
    try {
      addRawHexKey(
        utf8.encode(forHash).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      );
    } catch (_) {}
    return candidates;
  }

  static bool _isHexKey(String value) {
    if (value.length < 32 || value.length % 2 != 0) return false;
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);
  }

  static String _sqlQuote(String value) => "'${value.replaceAll("'", "''")}'";

  /// SQLCipher raw key: `x'<hex>'`. If [attachKey] is already hex (sha256/md5),
  /// use it directly. Do not UTF-8-hex that hex string again.
  static String _attachKeySql(String attachKey, {required bool useHex}) {
    if (!useHex) return _sqlQuote(attachKey);
    var hex = attachKey.trim();
    final wrapped = RegExp(r"^x'([0-9a-fA-F]+)'$", caseSensitive: false);
    final match = wrapped.firstMatch(hex);
    if (match != null) hex = match.group(1)!;
    if (_isHexKey(hex)) {
      return '"x\'${hex.toLowerCase()}\'"';
    }
    hex = utf8.encode(attachKey).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '"x\'$hex\'"';
  }

  static Future<bool> _fileHasPlainSqliteHeader(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final raf = await file.open();
      try {
        final bytes = await raf.read(16);
        if (bytes.length < 16) return false;
        return String.fromCharCodes(bytes) == 'SQLite format 3\x00';
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<void> _logDbFileHeader(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('DB_HEADER missing $path');
        return;
      }
      final raf = await file.open();
      try {
        final bytes = await raf.read(16);
        final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        final isPlain = bytes.length >= 16 &&
            String.fromCharCodes(bytes) == 'SQLite format 3\x00';
        debugPrint(
            'DB_HEADER size=${await file.length()} hex=$hex plainSqlite=$isPlain');
      } finally {
        await raf.close();
      }
    } catch (e) {
      debugPrint('DB_HEADER log failed: $e');
    }
  }

  static Future<void> _runPragma(sqlcipher.Database db, String sql) async {
    try {
      await db.rawQuery(sql);
    } catch (_) {
      await db.execute(sql);
    }
  }

  /// Native sqflite_sqlcipher keys immediately, so SQLCipher 3 / empty-key /
  /// raw-key files fail `openDatabase`. ATTACH can apply compatibility first.
  static Future<bool> _rekeyExistingDbViaAttach({
    required String path,
    required String outputPassword,
  }) async {
    if (!await File(path).exists()) return false;

    final recoveredPath = '$path.recovered';
    try {
      if (await File(recoveredPath).exists()) {
        await File(recoveredPath).delete();
      }
    } catch (_) {}

    final outputKeys = <String>{
      outputPassword,
      ...encryptionPasswordCandidates(),
    }.where((k) => k.isNotEmpty).toList();
    final attachKeys = <String>[...outputKeys, ''];

    sqlcipher.Database? newDb;
    try {
      newDb = await sqlcipher.openDatabase(
        recoveredPath,
        password: outputPassword,
        singleInstance: false,
      );
      final db = newDb!;

      for (final compat in <int>[4, 3, 2, 1]) {
        for (final attachKey in attachKeys) {
          for (final useHex in <bool>[false, true]) {
            if (useHex && attachKey.isEmpty) continue;
            try {
              await _setSqlCipherDefaultCompat(compat);
              await _runPragma(db, 'PRAGMA cipher_default_compatibility = $compat');
              if (compat <= 3) {
                await _runPragma(db, 'PRAGMA cipher_default_kdf_iter = 64000');
                await _runPragma(db, 'PRAGMA cipher_default_page_size = 1024');
              }
              final keySql = _attachKeySql(attachKey, useHex: useHex);
              await db.execute(
                  'ATTACH DATABASE ${_sqlQuote(path)} AS legacy KEY $keySql');
              final tables = await db.rawQuery(
                "SELECT name, sql FROM legacy.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND sql IS NOT NULL",
              );
              if (tables.isEmpty) {
                debugPrint(
                    'DB recover ATTACH ok but no tables compat=$compat keyLen=${attachKey.length} hex=$useHex');
                await db.execute('DETACH DATABASE legacy');
                continue;
              }

              for (final row in tables) {
                final name = row['name'] as String;
                final sql = row['sql'] as String;
                try {
                  await db.execute(sql);
                } catch (e) {
                  debugPrint('DB recover create $name: $e');
                }
                try {
                  await db.execute('INSERT INTO "$name" SELECT * FROM legacy."$name"');
                } catch (e) {
                  debugPrint('DB recover copy $name: $e');
                }
              }

              try {
                final extras = await db.rawQuery(
                  "SELECT sql FROM legacy.sqlite_master WHERE type IN ('index','trigger') AND sql IS NOT NULL AND name NOT LIKE 'sqlite_%'",
                );
                for (final row in extras) {
                  final sql = row['sql'] as String?;
                  if (sql != null && sql.isNotEmpty) {
                    try {
                      await db.execute(sql);
                    } catch (_) {}
                  }
                }
              } catch (_) {}

              await db.execute('DETACH DATABASE legacy');
              await db.close();
              newDb = null;

              final bakPath =
                  '$path.bak.${DateTime.now().millisecondsSinceEpoch}';
              await File(path).rename(bakPath);
              await File(recoveredPath).rename(path);
              debugPrint(
                  'DB recover rewritten via ATTACH compat=$compat keyLen=${attachKey.length} hex=$useHex bak=$bakPath');
              return true;
            } catch (e) {
              debugPrint(
                  'DB recover ATTACH failed compat=$compat keyLen=${attachKey.length} hex=$useHex: $e');
              try {
                await newDb?.execute('DETACH DATABASE legacy');
              } catch (_) {}
            }
          }
        }
      }
      try {
        await newDb?.close();
      } catch (_) {}
      try {
        if (await File(recoveredPath).exists()) await File(recoveredPath).delete();
      } catch (_) {}
      return false;
    } catch (e) {
      debugPrint('DB recover setup failed: $e');
      try {
        await newDb?.close();
      } catch (_) {}
      return false;
    }
  }

  static Future<sqlcipher.Database> openSqlCipherDatabase(
    String path, {
    String? password,
    int? version,
    Future<void> Function(dynamic db, int version)? onCreate,
    Future<void> Function(dynamic db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    await _logDbFileHeader(path);

    final fileExists = await File(path).exists();
    final passwords = <String>[
      if (password != null && password.isNotEmpty) password,
      ...encryptionPasswordCandidates(),
    ];
    final seen = <String>{};
    final uniquePasswords = <String>[
      for (final p in passwords)
        if (seen.add(p)) p,
    ];
    if (fileExists) {
      uniquePasswords.add('');
    }
    if (uniquePasswords.isEmpty) {
      throw StateError('No SQLCipher password available');
    }

    Object? lastError;
    const compatModes = <int?>[null, 4, 3, 2, 1];
    for (final compat in compatModes) {
      try {
        await _setSqlCipherDefaultCompat(compat);
      } catch (e) {
        debugPrint('DBHelper SQLCipher compat setup $compat: $e');
      }
      for (final candidate in uniquePasswords) {
        try {
          final db = await sqlcipher.openDatabase(
            path,
            version: fileExists ? null : version,
            password: candidate,
            onCreate: fileExists ? null : onCreate,
            onUpgrade: fileExists ? null : onUpgrade,
            singleInstance: false,
          );
          if (fileExists && !await _openedDbHasUserTables(db, path)) {
            debugPrint(
                'DBHelper SQLCipher false-open compat=${compat ?? "default"} keyLen=${candidate.length}');
            try {
              await db.close();
            } catch (_) {}
            continue;
          }
          debugPrint(
              'DBHelper SQLCipher open ok compat=${compat ?? "default"} keyLen=${candidate.length}');
          return db;
        } catch (e) {
          lastError = e;
          debugPrint(
              'DBHelper SQLCipher open failed compat=${compat ?? "default"} keyLen=${candidate.length}: $e');
        }
      }
    }

    final rewritePassword = uniquePasswords.firstWhere((p) => p.isNotEmpty,
        orElse: () => encryptionPassword() ?? '');
    if (rewritePassword.isNotEmpty && fileExists) {
      final recovered = await _rekeyExistingDbViaAttach(
        path: path,
        outputPassword: rewritePassword,
      );
      if (recovered) {
        final db = await sqlcipher.openDatabase(
          path,
          password: rewritePassword,
          singleInstance: false,
        );
        await ensureCurrentSchema(db);
        return db;
      }
    }

    throw lastError ?? StateError('SQLCipher open failed for $path');
  }

  /// Debug: Check what DB files exist on disk
  static Future<void> debugPrintDatabaseFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = [
        'bible.db',
        '.bible.db',
        'bible2.db',
        BibleEncryptedDbPaths.fileName,
      ];
      
      print('DB_FILES_CHECK: Checking database files in ${dir.path}');
      for (final filename in files) {
        final file = File(p.join(dir.path, filename));
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;
        print('DB_FILES_CHECK: $filename exists=$exists size=${size}bytes');
      }
    } catch (e) {
      print('DB_FILES_CHECK error: $e');
    }
  }

  /// Debug: log My Library row counts + encrypted DB path (filter logs: `LIBRARY_COUNTS`).
  static Future<void> debugPrintLibraryTableCounts() async {
    try {
      final db = await DBHelper().db;
      if (db == null) {
        print('LIBRARY_COUNTS DB is null');
        return;
      }
      final bookmark = await db.rawQuery("SELECT COUNT(*) as c FROM bookmark");
      final highlight =
          await db.rawQuery("SELECT COUNT(*) as c FROM highlight");
      final underline =
          await db.rawQuery("SELECT COUNT(*) as c FROM underline");
      final notes = await db.rawQuery("SELECT COUNT(*) as c FROM save_notes");
      print('LIBRARY_COUNTS BOOKMARK: ${bookmark.first['c']}');
      print('LIBRARY_COUNTS HIGHLIGHT: ${highlight.first['c']}');
      print('LIBRARY_COUNTS UNDERLINE: ${underline.first['c']}');
      print('LIBRARY_COUNTS NOTES: ${notes.first['c']}');
      print('LIBRARY_COUNTS DB PATH: ${db.path}');
      
      // Additional diagnostic: check if tables exist and show sample data
      try {
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        print('LIBRARY_COUNTS TABLES: ${tables.map((t) => t['name']).join(', ')}');
        
        if (bookmark.first['c'] as int > 0) {
          final sample = await db.rawQuery("SELECT id, book_num, chapter_num, verse_num FROM bookmark LIMIT 3");
          print('LIBRARY_COUNTS BOOKMARK_SAMPLE: $sample');
        }
      } catch (e) {
        print('LIBRARY_COUNTS table check error: $e');
      }
    } catch (e, st) {
      print('LIBRARY_COUNTS error: $e\n$st');
    }
  }

  initDatabase() async {
    final String path = await BibleEncryptedDbPaths.absolutePath();
    final password = dotenv.env[AssetsConstants.dbPasswordKey];

    Future<void> onUpgrade(dynamic db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
            'CREATE TABLE "calendar" (id INTEGER PRIMARY KEY AUTOINCREMENT,"title" TEXT,"date"	DATETIME)');
      }
      if (oldVersion < 3) {
        await db.execute(
            'CREATE TABLE IF NOT EXISTS "dailyVersesnew" (id INTEGER PRIMARY KEY AUTOINCREMENT, "Category_Name" TEXT, "Category_Id" INTEGER, "Book" TEXT, "Book_Id" INTEGER, "Chapter" INTEGER, "Verse" TEXT, "Date" TEXT, "Verse_Num" INTEGER)');

        try {
          await db.execute('ALTER TABLE bookmark ADD COLUMN plaincontent VARCHAR');
        } catch (e) {
          debugPrint('bookmark: plaincontent already exists or error: $e');
        }
        try {
          await db.execute('ALTER TABLE save_notes ADD COLUMN plaincontent VARCHAR');
        } catch (e) {
          debugPrint('save_notes: plaincontent already exists or error: $e');
        }
        try {
          await db.execute('ALTER TABLE highlight ADD COLUMN plain_content VARCHAR');
        } catch (e) {
          debugPrint('highlight: plain_content already exists or error: $e');
        }
        try {
          await db.execute('ALTER TABLE highlight ADD COLUMN verse_id VARCHAR');
        } catch (e) {
          debugPrint('highlight: verse_id already exists or error: $e');
        }
      }
    }

    debugPrint(
        'DBHelper.initDatabase opening: $path encryptedPasswordPresent=${password != null && password.isNotEmpty}');

    await _keepPreUpgradeCopy(path);
    await DBMigrationHelper.copyLegacyBibleEncIntoLiveIfMissing(path);

    final exists = await File(path).exists();
    if (exists) {
      try {
        final db = await tryOpenExisting128File(
          path,
          password: password,
          singleInstance: true,
        );
        if (db != null) {
          await ensureCurrentSchema(db);
          await DBMigrationHelper.restoreLibraryFrom128Backups(
            liveDb: db,
            password: password,
          );
          return db;
        }
      } catch (e) {
        debugPrint('DBHelper.initDatabase existing-file open failed: $e');
      }
    }

    // New install, or existing file could not be opened yet.
    try {
      final db = await openLiveOrRecoverEncrypted(
        path,
        password: password,
        version: 3,
        onCreate: (db, version) async {
          await _onCreate(db, version);
        },
        onUpgrade: onUpgrade,
      );
      await ensureCurrentSchema(db);
      await DBMigrationHelper.restoreLibraryFrom128Backups(
        liveDb: db,
        password: password,
      );
      return db;
    } catch (e) {
      debugPrint('DBHelper.initDatabase encrypted/plain open failed: $e');
    }

    // Plain sqlite only if the file really is unencrypted. Encrypted SQLCipher
    // files always fail here with code 26 and used to crash into the category screen.
    if (!exists || await _fileHasPlainSqliteHeader(path)) {
      try {
        return await plain.openDatabase(
          path,
          version: 3,
          onCreate: (db, version) async {
            await _onCreate(db, version);
          },
          onUpgrade: onUpgrade,
        );
      } catch (e) {
        debugPrint('DBHelper.initDatabase plain open failed: $e');
        rethrow;
      }
    }

    // Last resort: keep the 128 file on disk (never delete it), then create a
    // new live DB only so splash can continue. Restore copies library back.
    if (exists) {
      final adoptPassword = encryptionPassword() ?? password;
      if (adoptPassword != null && adoptPassword.isNotEmpty) {
        final adopted = await DBMigrationHelper.tryAdoptReadableEncryptedBackup(
          livePath: path,
          password: adoptPassword,
          version: 3,
          onCreate: (db, version) async {
            await _onCreate(db, version);
          },
          onUpgrade: onUpgrade,
        );
        if (adopted != null) return adopted;

        final keep =
            '$path.128-keep.${DateTime.now().millisecondsSinceEpoch}.bak';
        try {
          if (p.basename(path).contains('.bak')) {
            debugPrint('DBHelper last-resort refusing to delete bak $path');
          } else {
            final originalLength = await File(path).length();
            await File(path).copy(keep);
            await _copySqliteSidecars(path, keep);
            if (!await File(keep).exists() ||
                await File(keep).length() != originalLength) {
              throw StateError('128-keep copy missing or incomplete: $keep');
            }
            final keepHandle = await File(keep).open();
            await keepHandle.close();
            final keepDb = await tryOpenExisting128File(
              keep,
              password: adoptPassword,
            );
            if (keepDb != null) {
              try {
                await keepDb.close();
              } catch (_) {}
              debugPrint('DBHelper last-resort keep opened $keep');
            } else {
              debugPrint(
                  'DBHelper last-resort keep copied (undecryptable) $keep');
            }
            debugPrint(
                'DBHelper kept original bible_enc.db at $keep; creating a new live DB');
            try {
              await File(path).delete();
            } catch (_) {}
            for (final suffix in <String>['-wal', '-shm']) {
              try {
                await File('$path$suffix').delete();
              } catch (_) {}
            }
          }
          final db = await sqlcipher.openDatabase(
            path,
            version: 3,
            password: adoptPassword,
            onCreate: (db, version) async {
              await _onCreate(db, version);
            },
            onUpgrade: onUpgrade,
            singleInstance: false,
          );
          await DBMigrationHelper.restoreLibraryFrom128Backups(
            liveDb: db,
            password: adoptPassword,
          );
          return db;
        } catch (e) {
          debugPrint('DBHelper keep-original/create-new failed: $e');
        }
      }
    }

    throw StateError(
        'bible_enc.db exists but could not be decrypted (not a plain SQLite file)');
  }

  _onCreate(dynamic db, int version) async {
    try {
      await db.execute(
          'CREATE TABLE "calendar" (id INTEGER PRIMARY KEY AUTOINCREMENT,"title" TEXT,"date"	DATETIME)');
      await db.execute(
          'CREATE TABLE "verse" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num"	INTEGER, "chapter_num"	INTEGER, "verse_num"	INTEGER,"content"	TEXT,"is_read"	TEXT,"is_bookmarked"	TEXT,"is_underlined"	TEXT,"is_highlighted"	TEXT,"is_noted"	TEXT)');
      await db.execute(
          'CREATE TABLE "bookmark" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR,"bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "save_notes" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR,"book_name" VARCHAR, "notes" VARCHAR, "plaincontent" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "highlight" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plain_content" VARCHAR, verse_id VARCHAR, "book_name" VARCHAR,"color" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "underline" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR, "bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "book" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num"	INTEGER,"title"	TEXT,"short_title"	TEXT,"chapter_count"	INTEGER,"read_per"	TEXT)');
      await db.execute(
          'CREATE TABLE "save_images" (id INTEGER PRIMARY KEY AUTOINCREMENT,"image_path"	TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVersesMainList" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVerses" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
      await db.execute(
          'CREATE TABLE "dailyVersesnew" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
    } catch (e) {
      debugPrint('Error Creating Tables: $e');
    }
  }

////
  /// Calendar CRUD
  ///
////
  Future<void> saveCalendarData(CalendarModel calendar) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("calendar", calendar.toJson());
    } catch (_) {
      rethrow;
    }
  }

  Future<List<CalendarModel>> getCalendarData() async {
    try {
      var dbAccount = await db;
      final List<Map<String, Object?>> queryResult =
          await dbAccount!.query("calendar");
      return queryResult.map((e) => CalendarModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<int> deleteCalendarData(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("calendar", where: "id = ?", whereArgs: [id]);
  }

  Future<int> updateCalendarData(CalendarModel calendarData) async {
    var dbClient = await db;
    var res = await dbClient!.update("calendar", calendarData.toJson(),
        where: "id = ?", whereArgs: [calendarData.id]);
    return res;
  }

  ////
  /// End of Calendar CRUD
  ///
  ///.

  /// Save images
  Future<SaveImageModel> saveImage(SaveImageModel saveimagemodel) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("save_images", saveimagemodel.toJson());
    } catch (e) {
      // print(e);
    }
    return saveimagemodel;
  }

  ///
  ///
  ///
  Future<List<SaveImageModel>> getImage() async {
    try {
      var dbAccount = await db;
      final List<Map<String, Object?>> queryResult =
          await dbAccount!.query("save_images", orderBy: "id DESC");
      return queryResult.map((e) => SaveImageModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<int> deleteImage(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("save_images", where: "id = ?", whereArgs: [id]);
  }

  /// main Book List content

  Future<int> updateBookData(int id, String title, String value) async {
    var dbClient = await db;
    var res = await dbClient!
        .update("book", {title: value}, where: "id = ?", whereArgs: [id]);
    return res;
  }

  /// verse Book content
  Future<List<VerseBookContentModel>> getVerse() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("verse");
    debugPrint("queryResult V is  $queryResult");
    return queryResult.map((e) => VerseBookContentModel.fromJson(e)).toList();
  }

  Future<int> updateVersesData(int? id, String title, String value) async {
    if (id != null) {
      var dbClient = await db;
      var res = await dbClient!
          .update("verse", {title: value}, where: "id = ?", whereArgs: [id]);
      return res;
    }
    return 0;
  }

  Future<int> updateVersesDataBatch(
      int id, Map<String, dynamic> updates) async {
    var dbClient = await db;
    var res = await dbClient!.update(
      "verse",
      updates,
      where: "id = ?",
      whereArgs: [id],
    );
    return res;
  }

  Future<int> updateVersesDataByContent(
      String content, String title, String value) async {
    var dbClient = await db;
    var res = await dbClient!.update("verse", {title: value},
        where: "content = ?", whereArgs: [content]);
    return res;
  }

  Future<int> updateVersesDataByContentnew(
      String plainContent, String title, String value) async {
    final dbClient = await db;

    // Step 1: Get all verses
    final List<Map<String, dynamic>> verses = await dbClient!.query("verse");

    // Step 2: Find the one with matching plain text
    for (final verse in verses) {
      final htmlContent = verse["content"] ?? "";
      final parsedText = html_parser.parse(htmlContent).body?.text ?? "";
      // debugPrint(
      //     "check highlight - ${verse["id"]}  ${parsedText.trim()} =  ${plainContent.trim()}");
      if (parsedText.trim() == plainContent.trim()) {
        final int id = verse["id"];

        // Step 3: Update this verse
        return await dbClient.update(
          "verse",
          {title: value},
          where: "id = ?",
          whereArgs: [id],
        );
      }
    }

    return 0; // No match found
  }

  Future<int> updateVersesDataByContentnewcheck(
      String plainContent, String title, String value) async {
    final dbClient = await db;

    // Step 1: Get all verses
    final List<Map<String, dynamic>> verses = await dbClient!.query("verse");

    // Step 2: Find the one with matching plain text
    for (final verse in verses) {
      final htmlContent = verse["content"] ?? "";
      final parsedText = html_parser.parse(htmlContent).body?.text ?? "";

      if (parsedText.trim() == plainContent.trim()) {
        final int id = verse["id"];
        // debugPrint(
        //     "check highlight - ${verse["id"]}  ${parsedText.trim()} =  ${plainContent.trim()}");
        // Step 3: Update this verse
        return await dbClient.update(
          "verse",
          {title: value},
          where: "id = ?",
          whereArgs: [id],
        );
      }
    }

    return 0; // No match found
  }

  Future<int> updateVersesDataByContentmy(
      String content, String title, String value) async {
    // var dbClient = await db;
    // var res = await dbClient!.update("verse", {title: value},
    //     where: "content = ?", whereArgs: [content]);
    // return res;
    final dbClient = await db;
    try {
      final res = await dbClient!.update(
        'verse',
        {title: value},
        where: 'content = ?',
        whereArgs: [content],
      );
      return res;
    } catch (e) {
      debugPrint('Error updating verse: $e');
      return 0; // or -1 based on how you handle failure
    }
  }

  ///BookMark Functions
  Future<BookMarkModel> insertBookmark(BookMarkModel bookmarkmodel) async {
    var dbAccount = await db;
    try {
      final id = await dbAccount!.insert(
          "bookmark", _libraryInsertValues(bookmarkmodel.toJson()));
      debugPrint('insertBookmark id=$id');
    } catch (e) {
      debugPrint('insertBookmark failed: $e');
    }
    return bookmarkmodel;
  }

  ///
  ///
  ///
  Future<List<BookMarkModel>> getBookMark() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("bookmark", orderBy: "id DESC");
    return queryResult.map((e) => BookMarkModel.fromJson(e)).toList();
  }

  Future<int> deleteBookmark(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("bookmark", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteBookmarkByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("bookmark", where: "content = ?", whereArgs: [content]);
  }

  Future clearBookMarkTable() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("bookmark");
    } catch (e) {
      // print(e);
    }
  }

  /// Save Notes Functions
  Future<SaveNotesModel> insertNotes(SaveNotesModel savenotesmodel) async {
    var dbAccount = await db;
    try {
      final id = await dbAccount!.insert(
          "save_notes", _libraryInsertValues(savenotesmodel.toJson()));
      debugPrint('insertNotes id=$id');
    } catch (e) {
      debugPrint('insertNotes failed: $e');
    }
    return savenotesmodel;
  }

  ///
  ///
  ///
  Future<List<SaveNotesModel>> getNotes() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("save_notes", orderBy: "id DESC");
    // print(queryResult);
    return queryResult.map((e) => SaveNotesModel.fromJson(e)).toList();
  }

  Future<int> updateNotesData(
      String content, String title, String value) async {
    var dbClient = await db;
    var res = await dbClient!.update("save_notes", {title: value},
        where: "content = ?", whereArgs: [content]);
    return res;
  }

  Future<int> deleteNotes(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("save_notes", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteNotesByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("save_notes", where: "content = ?", whereArgs: [content]);
  }

  Future clearNotesTable() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("save_notes");
    } catch (e) {
      // print(e);
    }
  }

  ///Highlight Functions

  Future<HighLightContentModal> insertIntoHighLight(
      HighLightContentModal highlightcontentmodel) async {
    var dbAccount = await db;
    try {
      final id = await dbAccount!.insert(
          "highlight", _libraryInsertValues(highlightcontentmodel.toJson()));
      debugPrint('insertIntoHighLight id=$id');
    } catch (e) {
      debugPrint('insertIntoHighLight failed: $e');
    }
    return highlightcontentmodel;
  }

  ///
  ///
  ///
  Future<List<HighLightContentModal>> getHighlight() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("highlight", orderBy: "id DESC");
    // print(queryResult);
    return queryResult.map((e) => HighLightContentModal.fromJson(e)).toList();
  }

  Future<String?> getColorByContent(String content) async {
    var dbAccount = await db;
    // final List<Map<String, Object?>> queryResult = await dbAccount!.query(
    //   //   "highlight",
    //   //   where: "content = ?",
    //   //   whereArgs: [content],
    //   //  columns: ["color"],
    //   "highlight",
    //   where: "content = ?",
    //   whereArgs: [content],
    //   limit: 1, // We only need the first match
    // );

    final normalized = normalizeHtml(content);

    // debugPrint("highlight colr parse 2 : $normalized");

    final result = await dbAccount!.query(
      "highlight",
      where: "LOWER(plain_content) = LOWER(?)",
      whereArgs: [normalized],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first["color"]?.toString();
    }

    return null;

    // if (queryResult.isNotEmpty) {

    // return queryResult.first["color"] as String?;
    // }
    //  return null;
  }

  String normalizeHtml(String htmlContent) {
    final unescape = HtmlUnescape();
    final document = html_parser.parse(htmlContent);
    final normalized =
        unescape.convert(document.body?.text ?? htmlContent).trim();
    return normalized.replaceAll("'", '').replaceAll('"', '');
    // return unescape.convert(document.body?.text ?? htmlContent).trim();
    //return document.body?.text.trim() ?? htmlContent.trim();
  }

  // Stream<String?> getColorStreamByContent(String content) {
  //   return Stream.fromFuture(getColorByContent(content));
  // }

  Stream<String?> getColorStreamByContent(String content) async* {
    final color = await getColorByContent(content);
    yield color;
  }

  Future<int> deleteHighlight(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("highlight", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteHighlightByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("highlight", where: "content = ?", whereArgs: [content]);
  }

  Future<int> updateHighLight(
      HighLightContentModal highlight, content, data) async {
    var dbAccount = await db;
    return await dbAccount!.update("highlight", highlight.toJson(),
        where: '$content = ?', whereArgs: [data]);
  }

  Future clearHighLightTable() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("highlight");
    } catch (e) {
      // print(e);
    }
  }

  ///UnderLine Functions
  Future<BookMarkModel> insertUnderLine(BookMarkModel bookmarkmodel) async {
    var dbAccount = await db;
    try {
      final id = await dbAccount!.insert(
          "underline", _libraryInsertValues(bookmarkmodel.toJson()));
      debugPrint('insertUnderLine id=$id');
    } catch (e) {
      debugPrint('insertUnderLine failed: $e');
    }
    return bookmarkmodel;
  }

  ///
  ///
  ///
  Future<List<BookMarkModel>> getUnderLine() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("underline", orderBy: "id DESC");
    print(queryResult);
    return queryResult.map((e) => BookMarkModel.fromJson(e)).toList();
  }

  Future<int> deleteUnderline(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("underline", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteUnderlineByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("underline", where: "content = ?", whereArgs: [content]);
  }

  Future clearUnderLine() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("underline");
    } catch (e) {
      // print(e);
    }
  }

  Future<List<VerseBookContentModel>> getSelectedBookContent(
      selectedBookNum, selectedChapter) async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult = await dbAccount!.rawQuery(
        "SELECT * From verse WHERE book_num ='${int.parse(selectedBookNum)}' AND chapter_num = '${int.parse(selectedChapter) - 1}'");
    return queryResult.map((e) => VerseBookContentModel.fromJson(e)).toList();
  }
}

// class DBMigrationHelper {
//   static const _unencryptedDbName = 'bible.db';
//   static const _encryptedDbName = '.bible.db';
//   static const _newDbName = 'bible_enc.db'; // ✅ Target encrypted DB

//   static Future<String?> getSourceDbPath() async {
//     final dir = await getApplicationDocumentsDirectory();
//     final unencryptedPath = p.join(dir.path, _unencryptedDbName);
//     final encryptedPath = p.join(dir.path, _encryptedDbName);

//     if (await File(unencryptedPath).exists()) {
//       debugPrint("testapp Found unencrypted DB at: $unencryptedPath");
//       return unencryptedPath;
//     } else if (await File(encryptedPath).exists()) {
//       debugPrint("testapp Found encrypted DB at: $encryptedPath");
//       return encryptedPath;
//     }
//     return null;
//   }

//   static Future<String> getNewDbPath() async {
//     final dir = await getApplicationDocumentsDirectory();
//     return p.join(dir.path, _newDbName);
//   }

//   static Future<void> migrateToEncryptedDatabase(String password) async {
//     final sourceDbPath = await getSourceDbPath();
//     final newDbPath = await getNewDbPath();

//     if (await File(newDbPath).exists()) {
//       //debugPrint('testapp New encrypted DB already exists at $newDbPath');
//       return;
//     }

//     if (sourceDbPath == null || !await File(sourceDbPath).exists()) {
//       debugPrint('testapp No source DB found for migration.');
//       return;
//     }

//     // await EasyLoading.showInfo('Please wait... Updating database...');

//     final isUnencrypted = sourceDbPath.endsWith(_unencryptedDbName);

//     // // Step 1: Open source DB (plain or encrypted)
//     // final oldDb = isUnencrypted
//     //     ? await plain.openDatabase(sourceDbPath)
//     //     : await sqlcipher.openDatabase(sourceDbPath, password: password);

//     // // Step 2: Open new encrypted DB
//     // final newDb = await sqlcipher.openDatabase(
//     //   newDbPath,
//     //   password: password,
//     //   version: 3,
//     //   onCreate: (db, version) async {
//     //     await _createTables(db); // replicate schema
//     //   },
//     // );

//     // // Step 3: Copy tables and data
//     // final tables = await oldDb.rawQuery(
//     //     "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

//     // for (final tableMap in tables) {
//     //   final tableName = tableMap['name'] as String;
//     //   final rows = await oldDb.query(tableName);
//     //   for (final row in rows) {
//     //     try {
//     //       await newDb.insert(tableName, row);
//     //     } catch (e) {
//     //       debugPrint("testapp Error inserting into $tableName: $e");
//     //     }
//     //   }
//     // }

//     // Step 1: Open source DB (plain or encrypted)
//     late Database oldDb;
//     try {
//       oldDb = isUnencrypted
//           ? await plain.openDatabase(sourceDbPath)
//           : await sqlcipher.openDatabase(sourceDbPath, password: password);
//     } catch (e) {
//       debugPrint('Error opening source DB: $e');
//       return;
//     }

//     // Step 2: Create & open encrypted target DB
//     late Database newDb;
//     try {
//       newDb = await sqlcipher.openDatabase(
//         newDbPath,
//         password: password,
//         version: 3,
//         onCreate: (db, version) async {
//           await _createTables(db); // Ensure schema
//         },
//       );
//     } catch (e) {
//       debugPrint('Error creating encrypted DB: $e');
//       return;
//     }

//     // Step 3: Copy all tables
//     try {
//       final tables = await oldDb.rawQuery(
//           "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

//       for (final tableMap in tables) {
//         final tableName = tableMap['name'] as String;
//         final rows = await oldDb.query(tableName);
//         for (final row in rows) {
//           try {
//             await newDb.insert(tableName, row);
//           } catch (e) {
//             debugPrint("Insert error in '$tableName': $e");
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error during table migration: $e');
//     }

//     try {
//       final String dailyVerseResponse =
//           await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
//       final dailyVerseData = json.decode(dailyVerseResponse);

//       final dailyVerseDataList = List.from(dailyVerseData)
//           .map<DailyVersesMainListModel>(
//               (item) => DailyVersesMainListModel.fromJson(item))
//           .toList();

//       await newDb.transaction((txn) async {
//         await txn.delete('dailyVersesMainList');
//         final batch = txn.batch();

//         for (final item in dailyVerseDataList) {
//           final insertData = {
//             "Category_Name": item.mainCategory,
//             "Category_Id": item.categoryId,
//             "Book": item.book,
//             "Book_Id": item.bookId,
//             "Chapter": item.chapter,
//             "Verse": item.verse,
//           };
//           batch.insert('dailyVersesMainList', insertData);
//         }

//         final isUpload = await batch.commit();

//         if (isUpload.isNotEmpty) {
//           debugPrint("testapp dailyVersesMainList inserted successfully.");
//         }
//       });
//     } catch (e) {
//       debugPrint("testapp Error loading daily verses JSON: $e");
//     }

//     await oldDb.close();
//     await newDb.close();
//     // await EasyLoading.dismiss();

//     // try {
//     //   final dir = await getApplicationDocumentsDirectory();
//     //   final oldDbFile = File(p.join(dir.path, 'bible.db'));
//     //   if (await oldDbFile.exists()) {
//     //     await oldDbFile.delete();
//     //     debugPrint('Deleted old unencrypted DB: bible.db');
//     //   }

//     //   final dotDbFile = File(p.join(dir.path, '.bible.db'));
//     //   if (await dotDbFile.exists()) {
//     //     await dotDbFile.delete();
//     //     debugPrint('Deleted old encrypted DB: .bible.db');
//     //   }
//     // } catch (e) {
//     //   debugPrint('Error deleting old DB files: $e');
//     // }

//     debugPrint("testapp Migration to $newDbPath complete.");
//   }

class DBMigrationHelper {
  static const _unencryptedDbName = 'bible.db';
  static const _legacyEncryptedName = '.bible.db';
  static const _encryptedDbName = 'bible2.db';

  /// Per-table map: old column name -> new column name.
  /// bookmark uses plaincontent; highlight uses plain_content.
  static final Map<String, Map<String, String>> _columnMapForTable = {
    'bookmark': {
      'plain_content': 'plaincontent',
      'book_name': 'bookName',
    },
    'highlight': {
      'plaincontent': 'plain_content',
      'bookName': 'book_name',
      'verseid': 'verse_id',
    },
    'underline': {
      'plain_content': 'plaincontent',
      'book_name': 'bookName',
    },
    'save_notes': {
      'bookName': 'book_name',
      'plain_content': 'plaincontent',
    },
  };

  /// Rename legacy `.bible.db` → `bible2.db` only when the target is missing.
  /// Never delete `.bible.db` — 101/121 library may still be in that file.
  static Future<void> _renameLegacyEncryptedIfAny() async {
    final dir = await getApplicationDocumentsDirectory();
    final legacyPath = p.join(dir.path, _legacyEncryptedName);
    final newNamePath = p.join(dir.path, _encryptedDbName);

    if (await File(legacyPath).exists() && !await File(newNamePath).exists()) {
      try {
        await File(legacyPath).rename(newNamePath);
        print(
            "copyUserDataFromLegacyIfNeeded: renamed $_legacyEncryptedName → $_encryptedDbName");
      } catch (e) {
        print("copyUserDataFromLegacyIfNeeded: rename error: $e");
      }
    }
  }

  static Future<List<String>> _librarySearchDirs() async {
    final dirs = <String>{};
    Future<void> addDir(Future<Directory> Function() fn) async {
      try {
        dirs.add((await fn()).path);
      } catch (_) {}
    }

    await addDir(getApplicationDocumentsDirectory);
    await addDir(getApplicationSupportDirectory);
    try {
      dirs.add(await plain.getDatabasesPath());
    } catch (_) {}
    try {
      dirs.add((await getLibraryDirectory()).path);
    } catch (_) {}
    return dirs.toList();
  }

  /// If Documents has no live `bible_enc.db`, copy one from an older location
  /// (sqflite default path / support dir). Does not overwrite a real live file.
  static Future<void> copyLegacyBibleEncIntoLiveIfMissing(String livePath) async {
    try {
      final live = File(livePath);
      if (await live.exists() && await live.length() >= 4096) return;

      for (final dir in await _librarySearchDirs()) {
        final candidate = p.join(dir, BibleEncryptedDbPaths.fileName);
        if (p.equals(candidate, livePath)) continue;
        final src = File(candidate);
        if (!await src.exists() || await src.length() < 4096) continue;
        if (await live.exists()) {
          final keep =
              '$livePath.pre-missing-copy.${DateTime.now().millisecondsSinceEpoch}.bak';
          try {
            await live.copy(keep);
            await live.delete();
          } catch (_) {}
        }
        await src.copy(livePath);
        debugPrint(
            'copyLegacyBibleEncIntoLiveIfMissing: copied $candidate → $livePath');
        return;
      }
    } catch (e) {
      debugPrint('copyLegacyBibleEncIntoLiveIfMissing: $e');
    }
  }

  static Future<bool> _isDatabaseEncrypted(String path) async {
    try {
      final db = await plain.openDatabase(path);
      await db.rawQuery("SELECT name FROM sqlite_master LIMIT 1");
      await db.close();
      debugPrint("testapp DB at $path is UNENCRYPTED.");
      return false;
    } catch (_) {
      debugPrint("testapp DB at $path is ENCRYPTED or not plain.");
      return true;
    }
  }

  static Future<String?> getSourceDbPath() async {
    await _renameLegacyEncryptedIfAny();

    final dir = await getApplicationDocumentsDirectory();
    final unencryptedPath = p.join(dir.path, _unencryptedDbName);
    final maybeEncryptedPath = p.join(dir.path, _encryptedDbName);

    if (await File(unencryptedPath).exists()) {
      print("copyUserDataFromLegacyIfNeeded: found plain DB at: $unencryptedPath");
      return unencryptedPath;
    }
    if (await File(maybeEncryptedPath).exists()) {
      print("copyUserDataFromLegacyIfNeeded: found DB at: $maybeEncryptedPath");
      return maybeEncryptedPath;
    }
    return null;
  }

  static Future<String> getNewDbPath() => BibleEncryptedDbPaths.absolutePath();

  /// Quarantined / renamed copies of bible_enc.db from earlier 133 builds.
  /// Newest first. Never includes the live bible_enc.db.
  static Future<List<String>> _encryptedBackupDbPaths() async {
    final livePath = await getNewDbPath();
    final files = <File>[];
    final seen = <String>{};
    for (final dirPath in await _librarySearchDirs()) {
      try {
        await for (final entity in Directory(dirPath).list()) {
          if (entity is! File) continue;
          if (entity.path == livePath) continue;
          final name = p.basename(entity.path);
          final isBibleEncBak = name.startsWith(BibleEncryptedDbPaths.fileName) &&
              (name.contains('undecryptable') ||
                  name.contains('.bak') ||
                  name.contains('pre-upgrade') ||
                  name.contains('pre-adopt') ||
                  name.contains('pre-missing-copy') ||
                  name.contains('128-keep'));
          if (!isBibleEncBak) continue;
          if (!seen.add(entity.path)) continue;
          files.add(entity);
        }
      } catch (e) {
        debugPrint('_encryptedBackupDbPaths list failed: $e');
      }
    }
    files.sort((a, b) {
      try {
        return b.statSync().modified.compareTo(a.statSync().modified);
      } catch (_) {
        return b.path.compareTo(a.path);
      }
    });
    return files.map((f) => f.path).toList();
  }

  static Future<List<String>> _libraryCopySourcePaths() async {
    final livePath = await getNewDbPath();
    final paths = <String>[];
    final seen = <String>{};

    Future<void> add(String? path) async {
      if (path == null || path.isEmpty) return;
      if (p.equals(path, livePath)) return;
      if (!seen.add(path)) return;
      if (!await File(path).exists()) return;
      paths.add(path);
    }

    const names = [
      'bible.db',
      '.bible.db',
      'bible2.db',
      'bible_enc.db',
      'bible_enc.db.bak',
      'bible.db.bak',
      '.bible.db.bak',
    ];
    for (final dirPath in await _librarySearchDirs()) {
      for (final name in names) {
        await add(p.join(dirPath, name));
      }
    }
    await add(await getSourceDbPath());
    for (final bak in await _encryptedBackupDbPaths()) {
      await add(bak);
    }
    return paths;
  }

  static Future<int> _libraryRowCount(dynamic db) async {
    var total = 0;
    for (final table in _userDataTables) {
      try {
        final rows = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
        total += (rows.isNotEmpty ? (rows.first['c'] as int?) : 0) ?? 0;
      } catch (_) {}
    }
    return total;
  }

  static Future<bool> _candidateHeaderIsPlain(String path) async {
    try {
      final raf = await File(path).open();
      try {
        final bytes = await raf.read(16);
        if (bytes.length < 16) return false;
        return String.fromCharCodes(bytes) == 'SQLite format 3\x00';
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<({int bookmark, int highlight, int underline, int saveNotes})>
      _libraryFourCounts(dynamic db) async {
    Future<int> count(String table) async {
      try {
        final rows = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
        return (rows.isNotEmpty ? (rows.first['c'] as int?) : 0) ?? 0;
      } catch (_) {
        return 0;
      }
    }

    return (
      bookmark: await count('bookmark'),
      highlight: await count('highlight'),
      underline: await count('underline'),
      saveNotes: await count('save_notes'),
    );
  }

  static String _dbAuditPart(
    String path, {
    required bool plain,
    required bool opened,
    required ({int bookmark, int highlight, int underline, int saveNotes})
        counts,
  }) {
    final kind = plain ? 'plain' : 'encrypted';
    final total =
        counts.bookmark + counts.highlight + counts.underline + counts.saveNotes;
    return '${p.basename(path)}=$kind/open=$opened/bookmark=${counts.bookmark}/highlight=${counts.highlight}/underline=${counts.underline}/save_notes=${counts.saveNotes}/total=$total';
  }
    final book = row['book_num'];
    final chapter = row['chapter_num'];
    final verse = row['verse_num'];
    if (book == null || chapter == null || verse == null) return null;
    if (table == 'highlight') {
      return '$book|$chapter|$verse|${row['color']}';
    }
    if (table == 'save_notes') {
      return '$book|$chapter|$verse|${row['content']}';
    }
    return '$book|$chapter|$verse';
  }

  static DateTime? _libraryTimestamp(Map<String, Object?> row) {
    final value = row['timestamp'];
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _libraryRowIsNewer(
      Map<String, Object?> incoming, Map<String, Object?> existing) {
    final incomingTs = _libraryTimestamp(incoming);
    final existingTs = _libraryTimestamp(existing);
    if (incomingTs == null) return false;
    if (existingTs == null) return true;
    return incomingTs.isAfter(existingTs);
  }

  static String _libraryMergeWhereSql(String table) {
    if (table == 'highlight') {
      return 'book_num = ? AND chapter_num = ? AND verse_num = ? AND color IS ?';
    }
    if (table == 'save_notes') {
      return 'book_num = ? AND chapter_num = ? AND verse_num = ? AND content IS ?';
    }
    return 'book_num = ? AND chapter_num = ? AND verse_num = ?';
  }

  static List<Object?> _libraryMergeWhereArgs(
      String table, Map<String, Object?> row) {
    if (table == 'highlight') {
      return [row['book_num'], row['chapter_num'], row['verse_num'], row['color']];
    }
    if (table == 'save_notes') {
      return [
        row['book_num'],
        row['chapter_num'],
        row['verse_num'],
        row['content']
      ];
    }
    return [row['book_num'], row['chapter_num'], row['verse_num']];
  }

  static Future<void> _collectLibraryRowsFromDb(
    dynamic db,
    Map<String, Map<String, Map<String, Object?>>> merged,
  ) async {
    const tables = ['bookmark', 'highlight', 'underline', 'save_notes'];
    const aliases = {
      'bookmark': ['bookmark', 'bookmarks', 'book_mark', 'bookMark'],
      'highlight': ['highlight', 'highlights', 'high_light', 'highLight'],
      'underline': ['underline', 'underlines', 'under_line', 'underLine'],
      'save_notes': [
        'save_notes',
        'notes',
        'note',
        'saved_notes',
        'saveNotes'
      ],
    };
    for (final table in tables) {
      String? sourceTable;
      for (final name in aliases[table] ?? [table]) {
        try {
          final found = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            [name],
          );
          if (found.isNotEmpty) {
            sourceTable = name;
            break;
          }
        } catch (_) {}
      }
      if (sourceTable == null) continue;
      List<Map<String, Object?>> rows;
      try {
        rows = await db.query(sourceTable);
      } catch (_) {
        continue;
      }
      final dest = merged.putIfAbsent(table, () => {});
      for (final row in rows) {
        final mapped = Map<String, Object?>.from(row);
        if (table == 'highlight' &&
            mapped.containsKey('plaincontent') &&
            !mapped.containsKey('plain_content')) {
          mapped['plain_content'] = mapped['plaincontent'];
        }
        final key = _libraryMergeKey(table, mapped);
        if (key == null) continue;
        final existing = dest[key];
        if (existing == null || _libraryRowIsNewer(mapped, existing)) {
          dest[key] = mapped;
        }
      }
    }
  }

  static Future<void> _applyMergedLibraryRows(
    dynamic liveDb,
    Map<String, Map<String, Map<String, Object?>>> merged,
  ) async {
    for (final table in merged.keys) {
      List<String> targetColumns;
      try {
        targetColumns = await _getTableColumns(liveDb, table);
      } catch (_) {
        continue;
      }
      if (targetColumns.isEmpty) continue;
      for (final row in merged[table]!.values) {
        final mapped = _mapAndFilterRow(table, row, targetColumns);
        mapped.remove('id');
        if (mapped.isEmpty) continue;
        List<Map<String, Object?>> found;
        try {
          found = await liveDb.query(
            table,
            where: _libraryMergeWhereSql(table),
            whereArgs: _libraryMergeWhereArgs(table, mapped),
            limit: 1,
          );
        } catch (_) {
          found = const [];
        }
        if (found.isEmpty) {
          try {
            await liveDb.insert(table, mapped);
          } catch (e) {
            debugPrint('restoreLibrary merge insert $table: $e');
          }
          continue;
        }
        if (!_libraryRowIsNewer(mapped, found.first)) continue;
        final id = found.first['id'];
        if (id == null) continue;
        try {
          await liveDb.update(
            table,
            mapped,
            where: 'id = ?',
            whereArgs: [id],
          );
        } catch (e) {
          debugPrint('restoreLibrary merge update $table: $e');
        }
      }
    }
  }

  /// Bookmarks/highlights/underlines/notes only. Seeded calendar / images /
  /// dailyVersesMainList must not count as "library already restored".
  static Future<int> _libraryUserRowCount(dynamic db) async {
    var total = 0;
    for (final table in const [
      'bookmark',
      'highlight',
      'underline',
      'save_notes',
    ]) {
      try {
        final rows = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
        total += (rows.isNotEmpty ? (rows.first['c'] as int?) : 0) ?? 0;
      } catch (_) {}
    }
    return total;
  }

  /// If live bible_enc.db cannot be opened, use a readable backup that still
  /// has My Library rows. Keeps the unreadable file as `.pre-adopt.*.bak`.
  static Future<dynamic> tryAdoptReadableEncryptedBackup({
    required String livePath,
    required String password,
    int? version,
    Future<void> Function(dynamic db, int version)? onCreate,
    Future<void> Function(dynamic db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    final backups = await _encryptedBackupDbPaths();
    for (final bak in backups) {
      dynamic probe;
      try {
        probe = await DBHelper.tryOpenExisting128File(
          bak,
          password: password,
        );
        if (probe == null) {
          debugPrint('tryAdopt skip $bak (could not open)');
          continue;
        }
        final libraryCount = await _libraryRowCount(probe);
        await probe.close();
        probe = null;
        if (libraryCount <= 0) {
          debugPrint('tryAdopt skip $bak (no library rows)');
          continue;
        }

        final keep =
            '$livePath.pre-adopt.${DateTime.now().millisecondsSinceEpoch}.bak';
        await File(livePath).copy(keep);
        await DBHelper._copySqliteSidecars(livePath, keep);
        await File(bak).copy(livePath);
        await DBHelper._copySqliteSidecars(bak, livePath);
        debugPrint(
            'tryAdopt restored $bak → bible_enc.db; previous file kept at $keep');
        return await DBHelper.tryOpenExisting128File(
          livePath,
          password: password,
          singleInstance: true,
        );
      } catch (e) {
        debugPrint('tryAdopt skip $bak: $e');
        try {
          await probe?.close();
        } catch (_) {}
      }
    }
    return null;
  }

  static Future<bool> _targetDbHasCoreData(
      String targetPath, String password) async {
    try {
      final db =
          await DBHelper.openSqlCipherDatabase(targetPath, password: password);
      final verseCountRows =
          await db.rawQuery("SELECT COUNT(*) as c FROM verse");
      final bookCountRows = await db.rawQuery("SELECT COUNT(*) as c FROM book");
      final verseCount = verseCountRows.isNotEmpty
          ? (verseCountRows.first["c"] as int?) ?? 0
          : 0;
      final bookCount = bookCountRows.isNotEmpty
          ? (bookCountRows.first["c"] as int?) ?? 0
          : 0;
      await db.close();
      return verseCount > 0 && bookCount > 0;
    } catch (e) {
      debugPrint("testapp Target DB core-data check failed: $e");
      return false;
    }
  }

  /// IMPORTANT: don't delete existing user data.
  /// Some users may already have bookmarks/highlights/notes even when
  /// verse/book tables are empty at migration time.
  static Future<bool> _targetDbHasLibraryData(
      String targetPath, String password) async {
    try {
      final db =
          await DBHelper.openSqlCipherDatabase(targetPath, password: password);

      Future<int> countFrom(String table) async {
        try {
          final rows = await db.rawQuery("SELECT COUNT(*) as c FROM $table");
          return (rows.isNotEmpty ? (rows.first['c'] as int?) : null) ?? 0;
        } catch (_) {
          // Table may not exist in very old/corrupt DBs.
          return 0;
        }
      }

      final bookmarkCount = await countFrom('bookmark');
      final highlightCount = await countFrom('highlight');
      final underlineCount = await countFrom('underline');
      final notesCount = await countFrom('save_notes');

      await db.close();
      return bookmarkCount > 0 ||
          highlightCount > 0 ||
          underlineCount > 0 ||
          notesCount > 0;
    } catch (e) {
      debugPrint("testapp Target DB library-data check failed: $e");
      return false;
    }
  }

  /// Get columns from target table
  static Future<List<String>> _getTableColumns(
      sqlcipher.Database db, String table) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.map((row) => row['name'] as String).toList();
  }

  /// Filter + map old row to target schema (table-specific column names)
  static Map<String, Object?> _mapAndFilterRow(String tableName,
      Map<String, Object?> oldRow, List<String> targetColumns) {
    final tableMap = _columnMapForTable[tableName];
    final Map<String, Object?> mapped = {};
    oldRow.forEach((oldCol, value) {
      final newCol = (tableMap != null && tableMap.containsKey(oldCol))
          ? tableMap[oldCol]!
          : oldCol;
      if (targetColumns.contains(newCol)) {
        mapped[newCol] = value;
      }
    });
    return mapped;
  }

  static Future<void> migrateToEncryptedDatabase(String password) async {
    final sourceDbPath = await getSourceDbPath();
    final newDbPath = await getNewDbPath();

    if (await File(newDbPath).exists()) {
      // This file is the SAME path DBHelper opens (see BibleEncryptedDbPaths).
      final hasCore = await _targetDbHasCoreData(newDbPath, password);
      final hasLibrary = await _targetDbHasLibraryData(newDbPath, password);

      if (hasLibrary) {
        debugPrint(
            'testapp Target encrypted DB already has library data (core:${hasCore ? 1 : 0}, library:${hasLibrary ? 1 : 0}). Skipping migration.');
        return;
      }

      // ROOT CAUSE FIX: Never delete bible_enc.db while it still contains verse/book.
      // Old code logged "migrate user data only" but STILL ran delete → if no legacy
      // source remained, the file was gone and the next openDatabase created a NEW empty DB.
      if (hasCore) {
        debugPrint(
            'testapp Target encrypted DB has core data (verse/book). NOT deleting file — same DB app reads. Library copy runs via copyUserDataFromLegacyIfNeeded.');
        return;
      }

      // Open may have failed (wrong password) → both false; do not wipe a non-trivial file.
      final int fileSize = await File(newDbPath).length();
      const int minBytesToTreatAsRealDb = 4096;
      if (fileSize >= minBytesToTreatAsRealDb) {
        debugPrint(
            'testapp Target DB exists (${fileSize}b) but core/library probes empty — refusing delete (likely read/key issue, not empty DB).');
        return;
      }

      // Only rebuild from legacy when we can actually read a source file afterward.
      final bool sourceReady =
          sourceDbPath != null && await File(sourceDbPath).exists();
      if (!sourceReady) {
        debugPrint(
            'testapp Target looks empty but no legacy DB to rebuild from — NOT deleting bible_enc.db.');
        return;
      }

      try {
        final backupPath =
            '$newDbPath.bak.${DateTime.now().millisecondsSinceEpoch}';
        await File(newDbPath).copy(backupPath);
        debugPrint('testapp Backed up tiny/empty target DB to $backupPath');

        await File(newDbPath).delete();
        debugPrint(
            'testapp Removed tiny empty target DB; will migrate from legacy.');
      } catch (e) {
        debugPrint('testapp Failed to delete empty target DB: $e');
        return;
      }
    }
    if (sourceDbPath == null || !await File(sourceDbPath).exists()) {
      debugPrint('testapp No source DB found.');
      return;
    }

    final looksEncrypted = !sourceDbPath.endsWith(_unencryptedDbName)
        ? await _isDatabaseEncrypted(sourceDbPath)
        : false;

    // Open old DB
    dynamic oldDb;
    try {
      oldDb = looksEncrypted
          ? await DBHelper.openSqlCipherDatabase(sourceDbPath, password: password)
          : await plain.openDatabase(sourceDbPath);
    } catch (e) {
      debugPrint('testapp Error opening source DB: $e');
      return;
    }

    // Create new encrypted DB
    sqlcipher.Database? newDb;
    try {
      newDb = await DBHelper.openSqlCipherDatabase(
        newDbPath,
        password: password,
        version: 3,
        onCreate: (db, version) async {
          await _createTables(db);
        },
      );
    } catch (e) {
      debugPrint('testapp Error creating new DB: $e');
      await oldDb?.close();
      return;
    }

    /// Map legacy table names to current schema (so e.g. bookmarks -> bookmark).
    final Map<String, String> legacyTableToTarget = {
      'bookmarks': 'bookmark',
      'book_mark': 'bookmark',
      'bookMark': 'bookmark',
      'highlights': 'highlight',
      'high_light': 'highlight',
      'highLight': 'highlight',
      'underlines': 'underline',
      'under_line': 'underline',
      'underLine': 'underline',
      'notes': 'save_notes',
      'note': 'save_notes',
      'saved_notes': 'save_notes',
      'saveNotes': 'save_notes',
      'calender': 'calendar',
      'images': 'save_images',
      'saved_images': 'save_images',
      'saveImages': 'save_images',
      'daily_verses_main_list': 'dailyVersesMainList',
    };

    // Copy tables
    try {
      final tables = await oldDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      // Check if target already has core data to determine migration strategy
      final targetHasCore = await _targetDbHasCoreData(newDbPath, password);
      final userDataTables = ['bookmark', 'highlight', 'underline', 'save_notes', 'calendar', 'save_images'];

      for (final tableMap in tables) {
        final legacyTableName = tableMap['name'] as String;
        if (legacyTableName == 'android_metadata') continue;

        final targetTableName =
            legacyTableToTarget[legacyTableName] ?? legacyTableName;

        // CRITICAL FIX: If target has core data, only migrate user data tables
        if (targetHasCore && !userDataTables.contains(targetTableName)) {
          debugPrint("testapp Migration: skipping core table '$targetTableName' (target already has core data)");
          continue;
        }

        List<String> targetColumns;
        try {
          targetColumns = await _getTableColumns(newDb, targetTableName);
        } catch (_) {
          debugPrint(
              "testapp Migration: no target table '$targetTableName', skip.");
          continue;
        }
        if (targetColumns.isEmpty) continue;

        final rows = await oldDb.query(legacyTableName);
        for (final row in rows) {
          final mappedRow =
              _mapAndFilterRow(targetTableName, row, targetColumns);
          try {
            if (mappedRow.isNotEmpty) {
              await newDb.insert(targetTableName, mappedRow,
                  conflictAlgorithm: sqlcipher.ConflictAlgorithm.ignore);
            }
          } catch (e) {
            debugPrint("testapp Insert error in '$targetTableName': $e");
          }
        }
        if (rows.isNotEmpty) {
          debugPrint(
              "testapp Migration: copied ${rows.length} rows $legacyTableName -> $targetTableName");
        }
      }

      try {
        final String dailyVerseResponse =
            await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
        final dailyVerseData = json.decode(dailyVerseResponse) as List;
        final dailyVerseDataList = dailyVerseData
            .map<DailyVersesMainListModel>((item) =>
                DailyVersesMainListModel.fromJson(
                    Map<String, dynamic>.from(item as Map)))
            .toList();
        if (dailyVerseDataList.isEmpty) {
          debugPrint("testapp dailyVerse.json empty, keeping migrated data.");
        } else {
          await newDb.transaction((txn) async {
            await txn.delete('dailyVersesMainList');
            final batch = txn.batch();
            for (final item in dailyVerseDataList) {
              batch.insert('dailyVersesMainList', {
                "Category_Name": item.mainCategory ?? item.categoryName ?? '',
                "Category_Id": item.categoryId,
                "Book": item.book,
                "Book_Id": item.bookId,
                "Chapter": item.chapter,
                "Verse": item.verse?.toString() ?? '',
              });
            }
            await batch.commit();
            debugPrint("testapp dailyVersesMainList inserted successfully.");
          });
        }
      } catch (e) {
        debugPrint(
            "testapp Error loading daily verses JSON: $e (keeping migrated data)");
      }

      // CRITICAL: Verify migration was successful
      await _verifyMigrationSuccess(newDb, sourceDbPath!, password);
      debugPrint("testapp ✅ Migration finished successfully.");
    } catch (e) {
      debugPrint('testapp Migration error: $e');
    } finally {
      await oldDb?.close();
      await newDb.close();
    }
  }

  /// User-data and config tables to preserve on upgrade
  static const List<String> _userDataTables = [
    'bookmark',
    'highlight',
    'underline',
    'save_notes',
    'calendar',
    'save_images',
    'dailyVersesMainList',
  ];

  /// Verify that migration was successful by comparing data counts
  static Future<void> _verifyMigrationSuccess(
      sqlcipher.Database newDb, String sourceDbPath, String password) async {
    try {
      debugPrint("testapp Verifying migration success...");
      
      // Open source DB to compare counts
      final looksEncrypted = !sourceDbPath.endsWith('bible.db')
          ? await _isDatabaseEncrypted(sourceDbPath)
          : false;
      
      dynamic sourceDb = looksEncrypted
          ? await DBHelper.openSqlCipherDatabase(sourceDbPath, password: password)
          : await plain.openDatabase(sourceDbPath);

      for (final tableName in _userDataTables) {
        try {
          // Get count from source
          int sourceCount = 0;
          try {
            final sourceRows = await sourceDb.rawQuery("SELECT COUNT(*) as c FROM $tableName");
            sourceCount = (sourceRows.isNotEmpty ? (sourceRows.first['c'] as int?) : 0) ?? 0;
          } catch (_) {
            // Table might not exist in source
            continue;
          }

          // Get count from target
          final targetRows = await newDb.rawQuery("SELECT COUNT(*) as c FROM $tableName");
          final targetCount = (targetRows.isNotEmpty ? (targetRows.first['c'] as int?) : 0) ?? 0;

          debugPrint("testapp Migration verification: $tableName source=$sourceCount target=$targetCount");
          
          if (sourceCount > 0 && targetCount == 0) {
            debugPrint("testapp ⚠️ WARNING: $tableName has $sourceCount rows in source but 0 in target!");
          }
        } catch (e) {
          debugPrint("testapp Migration verification error for $tableName: $e");
        }
      }
      
      await sourceDb?.close();
    } catch (e) {
      debugPrint("testapp Migration verification failed: $e");
    }
  }

  /// Call from Library screens when data is empty to retry copying from legacy DB.
  static Future<void> tryRestoreLibraryDataFromLegacy() async {
    final password = DBHelper.encryptionPassword();
    if (password == null || password.isEmpty) return;
    await copyUserDataFromLegacyIfNeeded(password);
  }

  /// Emergency recovery method for users who already updated and lost data
  /// This method is more aggressive and will attempt multiple recovery strategies
  static Future<void> emergencyRecoverUserData() async {
    final password = DBHelper.encryptionPassword();
    if (password == null || password.isEmpty) {
      debugPrint('emergencyRecoverUserData: No password available');
      return;
    }

    debugPrint('emergencyRecoverUserData: Starting emergency recovery...');
    
    try {
      // Strategy 1: Try standard recovery
      await copyUserDataFromLegacyIfNeeded(password);
      
      // Strategy 2: Check for backup files that might exist
      final dir = await getApplicationDocumentsDirectory();
      final backupFiles = [
        'bible_enc.db.bak',
        'bible.db.bak',
        '.bible.db.bak'
      ];
      
      for (final backupFile in backupFiles) {
        final backupPath = p.join(dir.path, backupFile);
        if (await File(backupPath).exists()) {
          debugPrint('emergencyRecoverUserData: Found backup file $backupFile, attempting recovery...');
          try {
            // Try to recover from backup
            await _recoverFromBackupFile(backupPath, password);
          } catch (e) {
            debugPrint('emergencyRecoverUserData: Failed to recover from $backupFile: $e');
          }
        }
      }
      
      // Strategy 3: Look for any .bak files with timestamps
      final allFiles = await dir.list().toList();
      for (final entity in allFiles) {
        if (entity is File && entity.path.contains('.bak.')) {
          debugPrint('emergencyRecoverUserData: Found timestamped backup ${entity.path}');
          try {
            await _recoverFromBackupFile(entity.path, password);
          } catch (e) {
            debugPrint('emergencyRecoverUserData: Failed to recover from ${entity.path}: $e');
          }
        }
      }
      
      debugPrint('emergencyRecoverUserData: Emergency recovery completed');
    } catch (e) {
      debugPrint('emergencyRecoverUserData: Emergency recovery failed: $e');
    }
  }

  /// Attempt to recover user data from a backup file
  static Future<void> _recoverFromBackupFile(String backupPath, String password) async {
    final newDbPath = await getNewDbPath();
    
    // Try to open the backup file
    dynamic backupDb;
    try {
      // First try as encrypted
      backupDb = await sqlcipher.openDatabase(backupPath, password: password);
    } catch (_) {
      try {
        // Then try as unencrypted
        backupDb = await plain.openDatabase(backupPath);
      } catch (e) {
        debugPrint('_recoverFromBackupFile: Cannot open backup file $backupPath: $e');
        return;
      }
    }

    try {
      final newDb = await DBHelper().db;
      if (newDb == null) {
        debugPrint('_recoverFromBackupFile: live DB missing');
        return;
      }
      
      // Check if backup has user data
      bool hasUserData = false;
      for (final tableName in _userDataTables) {
        try {
          final rows = await backupDb.rawQuery("SELECT COUNT(*) as c FROM $tableName");
          final count = (rows.isNotEmpty ? (rows.first['c'] as int?) : 0) ?? 0;
          if (count > 0) {
            hasUserData = true;
            debugPrint('_recoverFromBackupFile: Found $count rows in $tableName');
            
            // Copy the data
            final data = await backupDb.query(tableName);
            final targetColumns = await _getTableColumns(newDb, tableName);
            
            for (final row in data) {
              final mappedRow = _mapAndFilterRow(tableName, row, targetColumns);
              mappedRow.remove('id'); // Remove ID to avoid conflicts
              if (mappedRow.isNotEmpty) {
                try {
                  await newDb.insert(tableName, mappedRow,
                      conflictAlgorithm: sqlcipher.ConflictAlgorithm.ignore);
                } catch (e) {
                  debugPrint('_recoverFromBackupFile: Insert error: $e');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('_recoverFromBackupFile: Error processing $tableName: $e');
        }
      }
      
      if (hasUserData) {
        debugPrint('_recoverFromBackupFile: Successfully recovered user data from $backupPath');
      } else {
        debugPrint('_recoverFromBackupFile: No user data found in $backupPath');
      }
    } finally {
      await backupDb?.close();
    }
  }

  static Future<bool> _libraryRowAlreadyExists(
      dynamic db, String table, Map<String, Object?> row) async {
    try {
      if (table == 'save_images') {
        final imagePath = row['image_path'];
        if (imagePath == null) return false;
        final found = await db.rawQuery(
          'SELECT 1 FROM save_images WHERE image_path = ? LIMIT 1',
          [imagePath],
        );
        return found.isNotEmpty;
      }
      if (table == 'calendar') {
        final title = row['title'];
        final date = row['date'];
        if (title == null) return false;
        final found = await db.rawQuery(
          'SELECT 1 FROM calendar WHERE title = ? AND date = ? LIMIT 1',
          [title, date],
        );
        return found.isNotEmpty;
      }
      final book = row['book_num'];
      final chapter = row['chapter_num'];
      final verse = row['verse_num'];
      final content = row['content'];
      if (book == null || chapter == null || verse == null) return false;
      if (content != null) {
        final found = await db.rawQuery(
          'SELECT 1 FROM $table WHERE book_num = ? AND chapter_num = ? AND verse_num = ? AND content = ? LIMIT 1',
          [book, chapter, verse, content],
        );
        return found.isNotEmpty;
      }
      final found = await db.rawQuery(
        'SELECT 1 FROM $table WHERE book_num = ? AND chapter_num = ? AND verse_num = ? LIMIT 1',
        [book, chapter, verse],
      );
      return found.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Copy My Library tables from a source DB into the live bible_enc.db.
  /// Source files are never deleted. Inserts use IGNORE so existing rows stay.
  static Future<void> _copyLibraryTablesFrom({
    required String sourceDbPath,
    required String password,
    required dynamic newDb,
  }) async {

    dynamic legacyDb;
    try {
      legacyDb = await DBHelper.tryOpenExisting128File(
        sourceDbPath,
        password: password,
      );
      legacyDb ??= await DBHelper.openLiveOrRecoverEncrypted(
        sourceDbPath,
        password: password,
        singleInstance: false,
      );
    } catch (e) {
      print('copyUserDataFromLegacyIfNeeded: could not open $sourceDbPath: $e');
      return;
    }
    if (legacyDb == null) {
      print('copyUserDataFromLegacyIfNeeded: could not open $sourceDbPath');
      return;
    }

    try {
      Future<bool> legacyHasTable(String name) async {
        try {
          final res = await legacyDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            [name],
          );
          return res.isNotEmpty;
        } catch (_) {
          return false;
        }
      }

      Future<String?> pickLegacyTable(List<String> candidates) async {
        for (final t in candidates) {
          if (await legacyHasTable(t)) return t;
        }
        return null;
      }

      const legacyCandidatesForTarget = {
        'bookmark': ['bookmark', 'bookmarks', 'book_mark', 'bookMark'],
        'highlight': ['highlight', 'highlights', 'high_light', 'highLight'],
        'underline': ['underline', 'underlines', 'under_line', 'underLine'],
        'save_notes': [
          'save_notes',
          'notes',
          'note',
          'saved_notes',
          'saveNotes'
        ],
        'calendar': ['calendar', 'calender'],
        'save_images': ['save_images', 'images', 'saved_images', 'saveImages'],
        'dailyVersesMainList': [
          'dailyVersesMainList',
          'daily_verses_main_list'
        ],
      };

      for (final tableName in _userDataTables) {
        try {
          final newCountRows =
              await newDb.rawQuery("SELECT COUNT(*) as c FROM $tableName");
          final newCount = (newCountRows.isNotEmpty
                  ? (newCountRows.first['c'] as int?)
                  : 0) ??
              0;
          debugPrint(
              'copyUserDataFromLegacyIfNeeded: $tableName current count=$newCount source=$sourceDbPath');

          final legacyTable = await pickLegacyTable(
            legacyCandidatesForTarget[tableName] ?? [tableName],
          );
          if (legacyTable == null) continue;

          final rows = await legacyDb.query(legacyTable);
          if (rows.isEmpty) {
            debugPrint(
                'copyUserDataFromLegacyIfNeeded: $legacyTable is empty, skipping');
            continue;
          }

          final targetColumns = await _getTableColumns(newDb, tableName);
          int copiedCount = 0;
          for (final row in rows) {
            final mappedRow = _mapAndFilterRow(tableName, row, targetColumns);
            mappedRow.remove('id');
            if (mappedRow.isEmpty) continue;
            if (await _libraryRowAlreadyExists(newDb, tableName, mappedRow)) {
              continue;
            }
            try {
              await newDb.insert(tableName, mappedRow,
                  conflictAlgorithm: sqlcipher.ConflictAlgorithm.ignore);
              copiedCount++;
            } catch (e) {
              debugPrint("testapp copyUserData insert '$tableName': $e");
            }
          }
          print(
              'copyUserDataFromLegacyIfNeeded: copied $copiedCount/${rows.length} rows from $legacyTable ($sourceDbPath) into $tableName');
        } catch (e) {
          print('copyUserDataFromLegacyIfNeeded: table $tableName error: $e');
        }
      }
    } finally {
      await legacyDb?.close();
    }
  }

  /// Merge My Library rows from live bible_enc.db and every readable .bak /
  /// legacy file. De-dupe by verse key and keep the newer timestamp.
  static Future<void> restoreLibraryFrom128Backups({
    required dynamic liveDb,
    String? password,
  }) async {
    if (liveDb == null) return;
    final livePath = await getNewDbPath();
    final pass = (password != null && password.isNotEmpty)
        ? password
        : (dotenv.env[AssetsConstants.dbPasswordKey] ??
            DBHelper.encryptionPassword() ??
            '');

    final sources = <String>[];
    final seen = <String>{};
    Future<void> addSource(String? path) async {
      if (path == null || path.isEmpty) return;
      if (!seen.add(path)) return;
      if (!await File(path).exists()) return;
      sources.add(path);
    }

    await addSource(livePath);
    for (final path in await _libraryCopySourcePaths()) {
      await addSource(path);
    }

    final merged = <String, Map<String, Map<String, Object?>>>{};
    final auditParts = <String>[];
    const zeros =
        (bookmark: 0, highlight: 0, underline: 0, saveNotes: 0);
    for (final sourceDbPath in sources) {
      final isLive = p.equals(sourceDbPath, livePath);
      final plain = await _candidateHeaderIsPlain(sourceDbPath);
      dynamic sourceDb;
      var opened = false;
      var counts = zeros;
      try {
        if (isLive) {
          sourceDb = liveDb;
        } else {
          sourceDb = await DBHelper.tryOpenExisting128File(
            sourceDbPath,
            password: pass,
          );
          sourceDb ??= await DBHelper.openLiveOrRecoverEncrypted(
            sourceDbPath,
            password: pass,
            singleInstance: false,
          );
        }
        if (sourceDb != null) {
          opened = true;
          counts = await _libraryFourCounts(sourceDb);
          await _collectLibraryRowsFromDb(sourceDb, merged);
        }
      } catch (e) {
        debugPrint('restoreLibraryFrom128Backups: skip $sourceDbPath: $e');
      } finally {
        auditParts.add(_dbAuditPart(sourceDbPath,
            plain: plain, opened: opened, counts: counts));
        if (!isLive) {
          try {
            await sourceDb?.close();
          } catch (_) {}
        }
      }
    }
    debugPrint(
        '[DB AUDIT] ${auditParts.isEmpty ? '(no database files)' : auditParts.join(' | ')}');

    var mergedTotal = 0;
    for (final tableRows in merged.values) {
      mergedTotal += tableRows.length;
    }
    if (mergedTotal == 0) {
      debugPrint('restoreLibraryFrom128Backups: no library rows in any source');
      return;
    }

    try {
      await liveDb.transaction((txn) async {
        await _applyMergedLibraryRows(txn, merged);
        final after = await _libraryUserRowCount(txn);
        if (after < mergedTotal) {
          throw StateError(
              'library verify failed live=$after uniqueSources=$mergedTotal');
        }
      });
    } catch (e) {
      debugPrint(
          'restoreLibraryFrom128Backups: abort verify $e (source files left untouched)');
      return;
    }
    final after = await _libraryUserRowCount(liveDb);
    debugPrint(
        'restoreLibraryFrom128Backups: merged $mergedTotal unique library rows; live now has $after');
  }

  /// If a 121/128 DB or a quarantined bible_enc.db backup still exists, copy
  /// My Library into the live file. Never deletes source files.
  static Future<void> copyUserDataFromLegacyIfNeeded(String password) async {
    final newDbPath = await getNewDbPath();
    final sources = await _libraryCopySourcePaths();
    final newExists = await File(newDbPath).exists();
    print(
        'copyUserDataFromLegacyIfNeeded start sources=$sources newDbPath=$newDbPath newExists=$newExists');

    if (!newExists) {
      print('copyUserDataFromLegacyIfNeeded: target DB missing ($newDbPath).');
      return;
    }

    if (sources.isEmpty) {
      print('copyUserDataFromLegacyIfNeeded: no legacy/backup DB to copy.');
      return;
    }

    dynamic newDb;
    try {
      newDb = await DBHelper().db;
    } catch (e) {
      print('copyUserDataFromLegacyIfNeeded: could not open new DB: $e');
      return;
    }
    if (newDb == null) {
      print('copyUserDataFromLegacyIfNeeded: could not open new DB: $newDbPath');
      return;
    }

    for (final sourceDbPath in sources) {
      await _copyLibraryTablesFrom(
        sourceDbPath: sourceDbPath,
        password: password,
        newDb: newDb,
      );
    }
  }

  static Future<void> _createTables(sqlcipher.Database db) async {
    try {
      await db.execute(
          'CREATE TABLE "calendar" (id INTEGER PRIMARY KEY AUTOINCREMENT,"title" TEXT,"date" DATETIME)');
      await db.execute(
          'CREATE TABLE "verse" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER,"content" TEXT,"is_read" TEXT,"is_bookmarked" TEXT,"is_underlined" TEXT,"is_highlighted" TEXT,"is_noted" TEXT)');
      await db.execute(
          'CREATE TABLE "bookmark" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR,"bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "save_notes" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR,"book_name" VARCHAR, "notes" VARCHAR, "plaincontent" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "highlight" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plain_content" VARCHAR, verse_id VARCHAR, "book_name" VARCHAR,"color" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "underline" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR, "bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "book" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER,"title" TEXT,"short_title" TEXT,"chapter_count" INTEGER,"read_per" TEXT)');
      await db.execute(
          'CREATE TABLE "save_images" (id INTEGER PRIMARY KEY AUTOINCREMENT,"image_path" TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVersesMainList" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVerses" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
      await db.execute(
          'CREATE TABLE "dailyVersesnew" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
    } catch (e) {
      debugPrint("testapp Error creating tables: $e");
    }
  }
}
