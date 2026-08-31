import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/utils/book_apps_helper.dart';
import 'package:biblebookapp/view/screens/more_apps/model/app_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final moreAppBloc = ChangeNotifierProvider<MoreAppBloc>((ref) => MoreAppBloc());

class MoreAppBloc extends ChangeNotifier {
  MoreAppBloc();

  int currentPage = 1;
  bool isLastPage = false;
  bool isLoading = false;
  List<AppModel> apps = [];

  resetApps() {
    apps = [];
    currentPage = 1;
    isLastPage = false;
    isLoading = false;
    customNotifyListeners();
  }

  Future getApps({bool reset = false}) async {
    if (reset) {
      resetApps();
    }
    try {
      if (!isLoading && !isLastPage) {
        isLoading = true;
        customNotifyListeners();
        final data = await getMoreApps();
        if (data.isEmpty) {
          isLastPage = true;
        }
        apps.addAll(data);
        currentPage++;
        isLoading = false;
        await StorageHelper.saveBooksAndApps(apps: apps);
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
