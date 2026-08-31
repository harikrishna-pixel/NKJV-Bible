import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/utils/book_apps_helper.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:flutter/foundation.dart';
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
        // Don't check connectivity upfront - it can be unreliable on first time
        // Proceed with API call and handle errors if they occur
        token = ++_loadToken;
        loadTimedOut = false;
        loadStatusMessage = null;
        isLoading = true;
        customNotifyListeners();
        final data = await getBookCategories(id);
        if (token != _loadToken) return;
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
      // Check if error is related to internet connection
      // Only show toast if it's a clear network error
      if (e.toString().contains('host lookup') || 
          e.toString().contains('No Internet Connection') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        Constants.showToast("No internet connection");
      }
      // Don't rethrow - allow the UI to show empty state gracefully
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
