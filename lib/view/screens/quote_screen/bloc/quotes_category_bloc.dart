import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final quotesCategoryBloc =
    ChangeNotifierProvider<QuotesCategoryBloc>((ref) => QuotesCategoryBloc());

class QuotesCategoryBloc extends ChangeNotifier {
  QuotesCategoryBloc();

  AsyncValue<List<CategoryModel>> quotesCategoryState = const AsyncLoading();

  Future getQuotesCategory() async {
    quotesCategoryState = const AsyncLoading();
    notifyListeners();
    try {
      final data = await getCategoryListing(isQuotes: true);
      quotesCategoryState = AsyncData(data);
    } catch (e, st) {
      quotesCategoryState = AsyncError(e, st);
    }
    notifyListeners();
  }
}
