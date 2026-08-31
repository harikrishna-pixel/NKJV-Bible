import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final wallpaperCategoryBloc = ChangeNotifierProvider<WallpaperCategoryBloc>(
    (ref) => WallpaperCategoryBloc());

class WallpaperCategoryBloc extends ChangeNotifier {
  WallpaperCategoryBloc();

  AsyncValue<List<CategoryModel>> wallpaperCategoryState = const AsyncLoading();

  Future getWallpaperCategory() async {
    wallpaperCategoryState = const AsyncLoading();
    notifyListeners();
    try {
      final data = await getCategoryListing(isQuotes: false);
      wallpaperCategoryState = AsyncData(data);
    } catch (e, st) {
      wallpaperCategoryState = AsyncError(e, st);
    }
    notifyListeners();
  }
}
