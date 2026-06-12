import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:biblebookapp/core/library_backup_upload_service.dart';
import 'package:biblebookapp/Model/overall_db_model.dart';
import 'package:biblebookapp/utils/custom_alert.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportDb {
  static String encryptionKey = dotenv.env['ENCRYPTION_KEY'] ?? '';

  static Future<Map<String, dynamic>> syncAllData() async {
    try {
      final bookmarkDataList = await DBHelper().getBookMark();
      final highlightsData = await DBHelper().getHighlight();
      final underlineData = await DBHelper().getUnderLine();
      final notesData = await DBHelper().getNotes();
      final imagesData = await DBHelper().getImage();
      final calendarData = await DBHelper().getCalendarData();
      // final verse = await DBHelper().getVerse();
      final rawWallpaperBookMark = await SharPreferences.getStringList(
          SharPreferences.wallpaperBookMark);
      final rawQuoteBookMark =
          await SharPreferences.getStringList(SharPreferences.quotesBookMark);
      OverallDbModel overAllDb = OverallDbModel(
        bookmark: bookmarkDataList,
        highlight: highlightsData,
        underline: underlineData,
        notes: notesData,
        // images: imagesData,
        wallpaper: rawWallpaperBookMark,
        calendar: calendarData,
        quotes: rawQuoteBookMark,
        //versecontent: verse
      );
      return overAllDb.toJson();
    } catch (e, st) {
      log('Error: $e, $st');
      rethrow;
    }
  }

  static Future<void> exportSuccessful(BuildContext context, String message,
      {required String path}) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: CommanColor.whiteLightModePrimary(context),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 2)
                          ],
                        ),
                        child: Text(
                          'Okay',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 14,
                              fontWeight: FontWeight.w500,
                              color: CommanColor.darkModePrimaryWhite(context)),
                        )),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      // final directory =
                      //     await getApplicationDocumentsDirectory();
                      final bibleDir = Directory(path);
                      try {
                        openFileManager(
                          androidConfig: AndroidConfig(
                            folderType: FolderType.recent,
                          ),
                          iosConfig: IosConfig(
                            // Path is case-sensitive here.
                            subFolderPath: bibleDir.path,
                          ),
                        );
                        // final data = await FilePicker.platform
                        //     .getDirectoryPath(initialDirectory: path);

                        // debugPrint("$data");
                      } catch (e) {
                        Constants.showToast("Something went wrong - $e.");
                      }
                    },
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: CommanColor.whiteLightModePrimary(context),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 2)
                          ],
                        ),
                        child: Text(
                          'View Backup',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 14,
                              fontWeight: FontWeight.w500,
                              color: CommanColor.darkModePrimaryWhite(context)),
                        )),
                  )
                ],
              ),
            ));
      },
    );
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    } else {
      // final status = await Permission.storage.status;

      // if (status.isDenied || status.isPermanentlyDenied) {
      //   final result = await Permission.storage.request();
      //   return result.isGranted;
      // }
      //return await Permission.storage.request().isGranted;
      return true;
    }
  }

  static Future<File> writeBackupFileToDirectory(Directory folder) async {
    final fileName = '${BibleInfo.bible_shortName}_Backup.enc';
    final jsonData = await syncAllData();
    final encodedData = encryptData(jsonEncode(jsonData));
    final file = File('${folder.path}/$fileName');
    await file.writeAsString(encodedData);
    return file;
  }

  static Future<void> getAllDataToExport(BuildContext context1) async {
    EasyLoading.show(status: "Please wait...");
    try {
      Directory? folder;
      Directory? directory;
      await SharPreferences.setString('OpenAd', '1');
      if (Platform.isAndroid) {
        directory = Directory(
            '/storage/emulated/0/${BibleInfo.bible_shortName}'); // Access Downloads
        await directory.create(recursive: true);
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        // String? selectedDirectory =
        //     await FilePicker.platform.getDirectoryPath();

        final Directory appDocDir = await getApplicationDocumentsDirectory();
        folder = Directory('${appDocDir.path}/${BibleInfo.bible_shortName}');

        // Create the folder if it doesn't exist
        if (!await folder.exists()) {
          await folder.create(recursive: true);
          debugPrint('Folder created at: ${folder.path}');
        }
        debugPrint('Selected Directory: ${folder.path}');
        // if (directory.path.isNotEmpty) {
        //   directory = Directory(directory.path);
        // } else {
        //   directory = null;
        // }
      }
      log('Directory: ${folder?.path}');
      await SharPreferences.setString('OpenAd', '1');
      if (folder != null) {
        final file = await writeBackupFileToDirectory(folder);
        await SharPreferences.setString(
            SharPreferences.lastExportedDate, DateTime.now().toString());
        unawaited(LibraryBackupUploadService.uploadBackupFile(file));
        // await Share.shareXFiles([XFile(file.path)], text: "Here is your file");

        await Future.delayed(Duration(seconds: 2));
        EasyLoading.dismiss();
        if (context1.mounted) {
          return showDialog(
            context: context1,
            builder: (_) => BackupDialog(
              type: "complete",
              onPrimaryPressed: () async {
                //  Navigator.pop(context);

                try {
                  openFileManager(
                    androidConfig: AndroidConfig(
                      folderType: FolderType.recent,
                    ),
                    iosConfig: IosConfig(
                      // Path is case-sensitive here.
                      subFolderPath: file.path,
                    ),
                  );
                  Get.back();
                  Get.back();
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              onSecondaryPressed: () {
                Get.back();
                Get.back();
              },
            ),
          );
          // Get.back();
        }
        // exportSuccessful(
        //     context,
        //     // "Data Exported Successfully to find Folder name as ${BibleInfo.bible_shortName} and back up file name is $fileName",
        //     "Data has been exported successfully. You can find the folder named ${BibleInfo.bible_shortName} and the backup file named $fileName.",
        //     path: file.path);
        // }
      } else {
        EasyLoading.dismiss();
        await SharPreferences.setString('OpenAd', '1');
        if (context1.mounted) {
          exportSuccessful(context1, " Folder is not selected", path: '');
        }
      }
    } catch (e, st) {
      EasyLoading.dismiss();
      await SharPreferences.setString('OpenAd', '1');
      log('Error: $e, $st');
      if (context1.mounted) {
        exportSuccessful(context1, " Error is $e and $st", path: '');
      }
      // rethrow;
    }
  }

  static Future<String> pickBibleFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        String filePath = result.files.single.path!;
        return filePath;
      } else {
        // throw 'No File Selected';
        return '';
      }
    } catch (e, st) {
      log('Error: $e,$st');
      //throw 'Error Picking Files';
      return '';
    }
  }

  static Future<void> saveAllData(String overallImportedDB) async {
    final jsonData = await jsonDecode(overallImportedDB);
    OverallDbModel overAllDB = OverallDbModel.fromJson(jsonData);
    await overAllDB.updateLocalDB();
    await overAllDB.updateLocalDBsync();
  }

  /// Local safety copy before cloud restore (does not change restore/import flows).
  static Future<void> createLocalSafetyCopyBeforeRestore() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final safetyRoot = Directory(
        '${appDir.path}/${BibleInfo.bible_shortName}/safety_backups',
      );
      if (!await safetyRoot.exists()) {
        await safetyRoot.create(recursive: true);
      }
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final folder = Directory('${safetyRoot.path}/$stamp');
      await folder.create(recursive: true);
      await writeBackupFileToDirectory(folder);
      debugPrint('Local safety backup saved: ${folder.path}');
    } catch (e, st) {
      log('createLocalSafetyCopyBeforeRestore: $e $st');
    }
  }

  /// Restores library data from an existing .enc backup file (e.g. cloud download).
  /// Does not change [importData] file-picker flow.
  static Future<String?> restoreBackupFromFile(File file) async {
    await SharPreferences.setString('OpenAd', '1');
    try {
      if (!await file.exists()) {
        Constants.showToast("File is not selected");
        return "File is not selected";
      }
      final encryptedContent = await file.readAsString();
      final decryptedContent = decryptData(encryptedContent);
      await saveAllData(decryptedContent);
      await Future.delayed(const Duration(seconds: 3));
      await SharPreferences.setString('OpenAd', '1');
      Constants.showToast(
          "Data Imported Successfully. Please restart app to see the changes");
      return null;
    } catch (e, st) {
      log('Error: $e,$st');
      await SharPreferences.setString('OpenAd', '1');
      Constants.showToast(e.toString());
      return e.toString();
    }
  }

  static Future importData() async {
    final filePath = await pickBibleFile();
    //  final filePath = await getApplicationDocumentsDirectory();
    await SharPreferences.setString('OpenAd', '1');
    try {
      // String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      debugPrint('Selected import Directory 2: $filePath');
      if (filePath.isNotEmpty) {
        // final file = File("$filePath/${BibleInfo.bible_shortName}_Backup.enc");
        final file = File(filePath);
        if (await file.exists()) {
          // Read the encrypted data from the file
          String encryptedContent = await file.readAsString();
          // Decrypt the data using the same encryption method
          String decryptedContent = decryptData(encryptedContent);
          await saveAllData(decryptedContent);
          await Future.delayed(Duration(seconds: 3));
          await SharPreferences.setString('OpenAd', '1');
          Constants.showToast(
              "Data Imported Successfully. Please restart app to see the changes");
        } else {
          Constants.showToast("File is not selected");
          await SharPreferences.setString('OpenAd', '1');
          throw Exception("File does not exist");
        }
      } else {
        Constants.showToast("File is not selected");
        await SharPreferences.setString('OpenAd', '1');
        return "File is not selected";
      }
    } catch (e, st) {
      log('Error: $e,$st');
      await SharPreferences.setString('OpenAd', '1');
      Constants.showToast(e.toString());
      return "File is not selected";
    }
  }

  // Function to encrypt data using AES
  static String encryptData(String plainText) {
    final key =
        encrypt.Key.fromUtf8(encryptionKey); // 32 characters for AES-256
    final iv = encrypt.IV.fromSecureRandom(16); // Generate a random 16-byte IV

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Concatenate the IV and the encrypted data
    final result = iv.bytes + encrypted.bytes;
    return base64UrlEncode(result); // Return as base64 string
  }

  // Function to decrypt the data using AES
  static String decryptData(String encryptedText) {
    final key =
        encrypt.Key.fromUtf8(encryptionKey); // Same key used in encryption

    // Decode the base64-encoded string
    final encryptedBytes = base64Url.decode(encryptedText);

    // Extract the IV (first 16 bytes) and the encrypted data
    final iv =
        encrypt.IV(encryptedBytes.sublist(0, 16)); // First 16 bytes for IV
    final encryptedData =
        encryptedBytes.sublist(16); // Rest is the encrypted data

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt(
      encrypt.Encrypted(encryptedData),
      iv: iv,
    );

    return decrypted; // Return the decrypted data
  }
}
