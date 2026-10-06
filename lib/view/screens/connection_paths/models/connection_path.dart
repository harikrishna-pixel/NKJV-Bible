import 'package:flutter/material.dart';

class PathDay {
  const PathDay({
    required this.title,
    required this.subtitle,
    required this.verseRef,
    required this.devotion,
    required this.reflection,
    required this.prayer,
  });

  final String title;
  final String subtitle;
  final String verseRef;
  final String devotion;
  final String reflection;
  final String prayer;
}

class ConnectionPath {
  const ConnectionPath({
    required this.id,
    required this.title,
    required this.tagline,
    required this.about,
    required this.icon,
    required this.days,
  });

  final String id;
  final String title;
  final String tagline;
  final String about;
  final IconData icon;
  final List<PathDay> days;

  int get durationDays => days.length;
  String get durationLabel => '$durationDays Days';
}

/// The four daily steps shown on the Daily Connection screen.
enum PathStep { verse, devotion, reflection, prayer }
