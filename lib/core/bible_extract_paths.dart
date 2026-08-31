import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Canonical paths for bible zip extraction under Documents.
class BibleExtractPaths {
  static String extractedDirName(String folderName) => '$folderName-extracted';

  static Future<String> extractedRoot(String folderName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/${extractedDirName(folderName)}';
  }

  static String canonicalBookJsonPath(String extractedRoot) =>
      '$extractedRoot/book.json';

  static String canonicalVerseJsonPath(String extractedRoot) =>
      '$extractedRoot/verse_json.json';

  /// Zip archives may ship an internal name like `verse_json 1.json`.
  static String outputNameForZipAsset(String zipAssetPath) {
    if (zipAssetPath.contains('verse_json')) return 'verse_json.json';
    return 'book.json';
  }

  static Future<File?> resolveVerseJsonFile(String folderName) async {
    final root = await extractedRoot(folderName);
    final canonical = File(canonicalVerseJsonPath(root));
    if (await canonical.exists()) return canonical;

    final dir = Directory(root);
    if (!await dir.exists()) return null;

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last.toLowerCase();
      if (name.startsWith('verse_json') && name.endsWith('.json')) {
        return entity;
      }
    }
    return null;
  }
}
