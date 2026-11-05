import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/utils/book_apps_helper.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/books/model/book_category_model.dart';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final bookBloc = ChangeNotifierProvider<BookBloc>((ref) => BookBloc());

class BookBloc extends ChangeNotifier {
  BookBloc();

  int currentPage = 1;
  bool isLastPage = false;
  bool isLoading = false;
  bool loadTimedOut = false;
  String? loadStatusMessage;
  List<BookModel> books = [];
  List<BookCategoryModel> categories = [];
  int _loadToken = 0;

  void cancelLoading({required String message}) {
    if (!isLoading) return;
    _loadToken++;
    isLoading = false;
    loadTimedOut = true;
    loadStatusMessage = message;
    customNotifyListeners();
  }

  void retryLoad(int id) {
    if (isLoading) return;
    loadTimedOut = false;
    loadStatusMessage = null;
    isLastPage = false;
    getBooks(id);
  }

  Future getBooks(int id) async {
    int? token;
    try {
      if (!isLoading && !isLastPage) {
        token = ++_loadToken;
        loadTimedOut = false;
        loadStatusMessage = null;
        isLoading = true;
        customNotifyListeners();
        final cats = await getBookCategoryList(id);
        if (token != _loadToken) return;
        categories = cats;
        final data = <BookModel>[];
        for (final cat in cats) {
          final catId = int.tryParse(cat.categoryId);
          if (catId == null) continue;
          final listed = await getBookListing(catId);
          if (token != _loadToken) return;
          data.addAll(listed.map((b) => b.copyWith(
                categoryId: cat.categoryId,
                categoryTitle: cat.categoryTitle,
              )));
        }
        // Some apps' getAppInfo `book_ads_app_id` holds a BookAds category id
        // (e.g. 18), which has no categories as an app id.
        if (cats.isEmpty) {
          final listed = await getBookListing(id);
          if (token != _loadToken) return;
          data.addAll(listed);
        }
        if (data.isEmpty) {
          isLastPage = true;
        }
        books = [];
        books.addAll(data);
        currentPage++;
        isLoading = false;
        await StorageHelper.saveBooksAndApps(books: books);
        customNotifyListeners();
      }
    } catch (e, _) {
      if (token != null && token != _loadToken) return;
      isLoading = false;
      customNotifyListeners();
      if (e.toString().contains('host lookup') ||
          e.toString().contains('No Internet Connection') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        Constants.showToast("No internet connection");
      }
    }
  }

  bool _isDisposed = false;

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
