import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/bookmark_shared_pref_bloc.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/listed_image_detail_screen.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/widget/image_card_widget.dart';
import 'package:biblebookapp/view/screens/quote_screen/quote_screen.dart';
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
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                SizedBox(
                  height: 20,
                ),
                InkWell(
                  onTap: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => );
                    Get.to(() => const QuoteScreen(),
                        transition: Transition.cupertinoDialog,
                        duration: const Duration(milliseconds: 300));
                  },
                  child: Column(
                    children: [
                      Image.asset(Images.quotesPlaceHolder(context),
                        height: 80, width: 80,color: Colors.transparent.withOpacity(0.3),),
                      const SizedBox(
                        height: 15,
                      ),
                      Text(
                        'No Quotes saved',
                        style: CommanStyle.placeholderText(context),
                      ),
                      SizedBox(height: 15,),
                      Container(
                        height: 40,
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              width: 2,
                              color: CommanColor.lightDarkPrimary300(context)
                          ),
                        ),
                        child: Center(
                          child: Text(" View ",
                              style: CommanStyle.placeholderText(context)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
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
