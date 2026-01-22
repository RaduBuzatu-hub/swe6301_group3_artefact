import 'package:flutter/material.dart';

/// Activity definitions used by Explore and detail screens.
/// Immutable activity metadata used in lists and details.
@immutable
class ActivityItem {
  final String title;
  final String location;
  final String meta;
  final String price;
  final String? assetPath;
  final String? imageUrl;
  final List<String> tags;
  final double rating;

  const ActivityItem({
    required this.title,
    required this.location,
    required this.meta,
    required this.price,
    this.assetPath,
    this.imageUrl,
    this.tags = const [],
    this.rating = 0,
  });
}

/// Static seed data for demo activities.
const List<ActivityItem> kActivities = [
  ActivityItem(
    title: 'Coastal Clean-Up Experience',
    location: 'Falmouth Beach, Cornwall',
    meta: 'Free - 3-hour session',
    price: 'Free',
    assetPath: 'lib/screens/assets/beach_clean_up.png',
    tags: ['beach', 'cornwall', 'outdoor', 'clean-up'],
    rating: 4.5,
  ),
  ActivityItem(
    title: 'Forest Replanting',
    location: 'Dartmoor',
    meta: 'Free · Half-day',
    price: 'Free',
    assetPath: 'lib/screens/assets/forest_replanting.png',
    tags: ['forest', 'outdoor', 'tree planting'],
    rating: 4.6,
  ),
  ActivityItem(
    title: 'Eco Cooking Workshop (Lisbon)',
    location: 'Lisbon',
    meta: 'Workshop · 2 hrs',
    price: 'EUR 10',
    assetPath: 'lib/screens/assets/island_hideaway.jpeg',
    tags: ['workshop', 'food', 'lisbon'],
    rating: 4.2,
  ),
  ActivityItem(
    title: 'Eco Cooking Workshop (Online)',
    location: 'Online',
    meta: 'Workshop · 2 hrs',
    price: 'Free',
    assetPath: 'lib/screens/assets/eco_cooking_workshop.jpeg',
    tags: ['workshop', 'online', 'virtual'],
    rating: 4.1,
  ),
];




