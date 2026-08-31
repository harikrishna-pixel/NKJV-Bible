import 'dart:convert';
import 'dart:developer';

import 'package:biblebookapp/Model/image_model.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final bookmarkSharedPrefBloc = ChangeNotifierProvider<BookmarkSharedPrefBloc>(
    (ref) => BookmarkSharedPrefBloc());

class BookmarkSharedPrefBloc extends ChangeNotifier {
  List<ImageModel> quotesBookmark = [];
  List<ImageModel> wallpaperBookmark = [];

  getBookmarks() async {
    final rawWallpaperBookMark =
        await SharPreferences.getStringList(SharPreferences.wallpaperBookMark);
    final rawQuoteBookMark =
        await SharPreferences.getStringList(SharPreferences.quotesBookMark);

    quotesBookmark = (rawQuoteBookMark ?? [])
        .map((e) => ImageModel.fromJson(jsonDecode(e)))
        .toList();
    wallpaperBookmark = (rawWallpaperBookMark ?? [])
        .map((e) => ImageModel.fromJson((jsonDecode(e))))
        .toList();
    notifyListeners();
  }

  isIdBookMarked(String? id, bool isWallpaper) {
    if (isWallpaper) {
      final index = wallpaperBookmark.indexWhere((e) => e.imageId == id);
      return index != -1;
    } else {
      final index = quotesBookmark.indexWhere((e) => e.imageId == id);
      return index != -1;
    }
  }

  _addBookmarkImage(ImageModel image, bool isWallpaper) {
    if (isWallpaper) {
      wallpaperBookmark.add(image);
      SharPreferences.setListString(SharPreferences.wallpaperBookMark,
          wallpaperBookmark.map((e) => jsonEncode(e)).toList());
    } else {
      quotesBookmark.add(image);
      SharPreferences.setListString(SharPreferences.quotesBookMark,
          quotesBookmark.map((e) => jsonEncode(e)).toList());
    }
    notifyListeners();
  }

  _removeBookmarkImage(ImageModel image, bool isWallpaper) {
    try {
      if (isWallpaper) {
        final index =
            wallpaperBookmark.indexWhere((e) => e.imageId == image.imageId);
        wallpaperBookmark.removeAt(index);
        SharPreferences.setListString(SharPreferences.wallpaperBookMark,
            wallpaperBookmark.map((e) => jsonEncode(e)).toList());
      } else {
        final index =
            quotesBookmark.indexWhere((e) => e.imageId == image.imageId);
        quotesBookmark.removeAt(index);
        SharPreferences.setListString(SharPreferences.quotesBookMark,
            quotesBookmark.map((e) => jsonEncode(e)).toList());
      }
      notifyListeners();
    } catch (e, st) {
      log("Error: $e, $st");
    }
  }

  toggleBookMarkImage(ImageModel image, bool isWallpaper) {
    log('Toggle');
    final isBookmarked = isIdBookMarked(image.imageId, isWallpaper);
    log('Is Bookmarked: $isBookmarked');
    if (isBookmarked) {
      _removeBookmarkImage(image, isWallpaper);
    } else {
      _addBookmarkImage(image, isWallpaper);
    }
  }
}
