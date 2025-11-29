import 'package:flutter/material.dart';

@immutable
class ActivityItem {
  final String title;
  final String location;
  final String meta;
  final String price;
  final String? assetPath;
  final String? imageUrl;
  final List<String> tags;

  const ActivityItem({
    required this.title,
    required this.location,
    required this.meta,
    required this.price,
    this.assetPath,
    this.imageUrl,
    this.tags = const [],
  });
}

const List<ActivityItem> kActivities = [
  ActivityItem(
    title: 'Beach Clean-Up - Saturday',
    location: 'Falmouth Beach, Cornwall',
    meta: 'Free · 10:00-13:00',
    price: 'Free',
    assetPath: 'lib/screens/assets/beach_clean_up.png',
    tags: ['beach', 'cornwall', 'outdoor', 'clean-up'],
  ),
  ActivityItem(
    title: 'Forest Replanting',
    location: 'Dartmoor',
    meta: 'Free · Half-day',
    price: 'Free',
    assetPath: 'lib/screens/assets/forest_replanting.png',
    tags: ['forest', 'outdoor', 'tree planting'],
  ),
  ActivityItem(
    title: 'Eco Cooking Workshop (Lisbon)',
    location: 'Lisbon',
    meta: 'Workshop · 2 hrs',
    price: 'EUR 10',
    assetPath: 'lib/screens/assets/island_hideaway.jpeg',
    tags: ['workshop', 'food', 'lisbon'],
  ),
  ActivityItem(
    title: 'Eco Cooking Workshop (Online)',
    location: 'Online',
    meta: 'Workshop · 2 hrs',
    price: 'Free',
    assetPath: 'lib/screens/assets/beach_clean_up.png',
    tags: ['workshop', 'online', 'virtual'],
  ),
];
