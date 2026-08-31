import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/Model/image_model.dart';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final fetchedPhotosBloc =
    ChangeNotifierProvider.family<FetchedPhotosBloc, CategoryModel>(
        (ref, cat) => FetchedPhotosBloc(cat));

class FetchedPhotosBloc extends ChangeNotifier {
  final CategoryModel category;
  FetchedPhotosBloc(this.category);

  int currentPage = 1;
  bool isLastPage = false;
  bool isLoading = false;
  List<ImageModel> photos = [];

  resetPhotos() {
    photos = [];
    currentPage = 1;
    isLastPage = false;
    isLoading = false;
    customNotifyListeners();
  }

  Future getPhotos({bool reset = false}) async {
    if (reset) {
      resetPhotos();
    }
    try {
      if (!isLoading && !isLastPage) {
        isLoading = true;
        customNotifyListeners();
        final data =
            await getImageListing(id: category.id ?? '', page: currentPage);
        if (data.isEmpty) {
          isLastPage = true;
        }
        photos.addAll(data);
        currentPage++;
        isLoading = false;
        customNotifyListeners();
      }
    } catch (e, _) {
      isLoading = false;
      customNotifyListeners();
      rethrow;
    }
  }

  // to indicate whether the state provider is disposed or not
  bool _isDisposed = false;

  // use the notifyListeners as below
  customNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _isDisposed = true;
  }
}
