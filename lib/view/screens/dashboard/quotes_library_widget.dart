import 'package:biblebookapp/view/screens/category_detail_screen/bloc/bookmark_shared_pref_bloc.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/listed_image_detail_screen.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/widget/image_card_widget.dart';
import 'package:biblebookapp/view/screens/quote_screen/quote_screen.dart';
import 'package:biblebookapp/view/widget/library_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuotesLibraryWidget extends HookConsumerWidget {
  const QuotesLibraryWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesBookmarkList = ref.watch(bookmarkSharedPrefBloc).quotesBookmark;
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((callback) {
        ref.read(bookmarkSharedPrefBloc).getBookmarks();
      });
    });
    return quotesBookmarkList.isEmpty
        ? SizedBox.expand(
            child: LibraryEmptyState(
              icon: Icons.format_quote_outlined,
              title: 'No Quotes Yet',
              subtitle: 'Save quotes to access them anytime.',
              buttonLabel: 'View',
              onButtonPressed: () {
                Get.to(
                  () => const QuoteScreen(),
                  transition: Transition.cupertinoDialog,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
          )
        : GridView.custom(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                crossAxisCount: 2,
                childAspectRatio: 9 / 16),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) {
                return GestureDetector(
                  onTap: () {
                    Get.to(
                        () => ListedImageDetailScreen(
                            index: index,
                            photos: quotesBookmarkList,
                            isWallpaper: false),
                        transition: Transition.cupertinoDialog,
                        duration: const Duration(milliseconds: 300));
                  },
                  child: ImageCardWidget(
                      url: quotesBookmarkList[index].imageUrl ?? ''),
                );
              },
              childCount: quotesBookmarkList.length,
            ));
  }
}
