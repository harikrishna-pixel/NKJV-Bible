import 'package:flutter/material.dart';

class LibraryStatusModel {
  final String title;
  final Widget leading;
  final int count;
  LibraryStatusModel(
      {required this.leading, required this.count, required this.title});
}
