import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class ExtractZipJson {
  static Future<String> extractFile(String path, String zipPassword) async {
    // Load the zip file from assets
    final ByteData data = await rootBundle.load(path);
    final Uint8List bytes = data.buffer.asUint8List();

    // Retrieve the password from environment variables
    String password = dotenv.env[zipPassword] ?? '';

    // Decode the Zip file, ensuring bytes are mutable
    final archive =
        ZipDecoder().decodeBytes(List<int>.from(bytes), password: password);

    // Get the first file (assuming there's only one)
    final file = archive.files.first;

    // Check if the file is indeed a file (not a directory)
    if (!file.isFile) {
      throw Exception('The extracted item is not a file.');
    }

    // Get the application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();

    final filePath = '${appDocDir.path}/${file.name}';
    List<int> rawData = file.content is Uint8List
        ? List<int>.from(file.content)
        : file.content as List<int>;
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(rawData);
    final content = await File(filePath).readAsString();
    return content;
  }
}
