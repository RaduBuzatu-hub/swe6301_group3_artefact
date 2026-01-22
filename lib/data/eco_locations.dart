import 'package:flutter/material.dart';

/// Seed data and model for eco-friendly stay locations.

@immutable
/// Immutable model representing a stay/location in Explore and detail screens.
class EcoLocation {
  final String title;
  final String location;
  final String meta;
  final String price;
  final String imageUrl;
  final List<String> tags;
  final double rating;

  const EcoLocation({
    required this.title,
    required this.location,
    required this.meta,
    required this.price,
    required this.imageUrl,
    this.tags = const [],
    this.rating = 0,
  });
}

/// Static list of demo locations used by Explore and Home screens.
const List<EcoLocation> kEcoLocations = [
  EcoLocation(
    title: 'Thames Eco Stay',
    location: 'London · Zone 2',
    meta: 'Local owned · Solar powered',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&w=1200&q=80',
    tags: ['london', 'train', 'uk'],
    rating: 4.7,
  ),
  EcoLocation(
    title: 'Camden Green Hostel',
    location: 'London',
    meta: 'Vegan friendly · Free bikes',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1433838552652-f9a46b332c40?auto=format&w=1200&q=80',
    tags: ['london', 'budget', 'hostel', 'uk'],
    rating: 4.2,
  ),
  EcoLocation(
    title: 'Cornwall Clifftop Cabin',
    location: 'Cornwall',
    meta: 'Sea view · Wood-fired hot tub',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1505761671935-60b3a7427bad?auto=format&w=1200&q=80',
    tags: ['cornwall', 'sea', 'uk'],
    rating: 4.8,
  ),
  EcoLocation(
    title: 'Cornwall Eco Farmstay',
    location: 'Cornwall',
    meta: 'Organic farm · Solar powered',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&w=1200&q=80',
    tags: ['cornwall', 'farm', 'uk'],
    rating: 4.4,
  ),
  EcoLocation(
    title: 'Lake District Lodge',
    location: 'Lake District',
    meta: 'Wood-fired sauna · Lakeside',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&w=1200&q=80',
    tags: ['lake', 'uk', 'lodge'],
    rating: 4.6,
  ),
  EcoLocation(
    title: 'Seaside Escape',
    location: 'Cornwall',
    meta: 'Clifftop views · Private cove',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1200&q=80',
    tags: ['cornwall', 'sea', 'escape'],
    rating: 4.5,
  ),
  EcoLocation(
    title: 'Mountain Retreat',
    location: 'Swiss Alps',
    meta: 'Chalet · Sauna · Glacier hikes',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&w=1200&q=80',
    tags: ['alps', 'mountain', 'switzerland'],
    rating: 4.9,
  ),
  EcoLocation(
    title: 'Island Hideaway',
    location: 'Bali',
    meta: 'Jungle villa · Plunge pool',
    price: '£150 / night',
    imageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&w=1200&q=80',
    tags: ['bali', 'island', 'asia'],
    rating: 4.3,
  ),
];
