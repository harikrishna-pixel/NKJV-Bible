import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/category_detail_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryWidget extends StatelessWidget {
  const CategoryWidget(
      {super.key, required this.category, required this.isWallpaper});
  final CategoryModel category;
  final bool isWallpaper;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Get.to(
              () => CategoryDetailScreen(
                  category: category, isWallpaper: isWallpaper),
              transition: Transition.cupertinoDialog,
              duration: const Duration(milliseconds: 300));
        },
        child: CachedNetworkImage(
          imageUrl: category.thumbnail ?? '',
          progressIndicatorBuilder: (context, url, progress) =>
              const CupertinoActivityIndicator(),
          imageBuilder: (context, imageProvider) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: imageProvider,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.55), BlendMode.srcATop),
                    fit: BoxFit.cover),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  category.name ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: BibleInfo.letterSpacing,
                      fontSize: BibleInfo.fontSizeScale * 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
            );
          },
        ));
  }
}
