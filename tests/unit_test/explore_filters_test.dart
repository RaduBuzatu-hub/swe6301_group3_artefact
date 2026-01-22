/// Unit tests for ExploreFilters query, filter, and sort logic.
import 'package:flutter_test/flutter_test.dart';
import 'package:swe6301_group3_artefact/data/activities.dart';
import 'package:swe6301_group3_artefact/data/eco_locations.dart';
import 'package:swe6301_group3_artefact/utils/explore_filters.dart';

void main() {
  // Core filtering and sorting behavior for activities/stays.
  group('ExploreFilters activities', () {
    test('filters by category for activities and stays', () {
      final activityFilters = ExploreFilters(
        currentQuery: 'Explore',
        activeFilters: const <String>{},
        categoryFilter: ExploreCategoryFilter.activities,
        selectedLocation: 'Anywhere',
        selectedEcoTag: 'Any tag',
        sortOption: ExploreSortOption.ratingDesc,
      );

      final activities = activityFilters.filterActivities(kActivities);
      final locations = activityFilters.filterLocations(kEcoLocations);
      expect(activities, hasLength(kActivities.length));
      expect(locations, isEmpty);

      final stayFilters = ExploreFilters(
        currentQuery: 'Explore',
        activeFilters: const <String>{},
        categoryFilter: ExploreCategoryFilter.stays,
        selectedLocation: 'Anywhere',
        selectedEcoTag: 'Any tag',
        sortOption: ExploreSortOption.ratingDesc,
      );

      expect(stayFilters.filterActivities(kActivities), isEmpty);
      expect(stayFilters.filterLocations(kEcoLocations), hasLength(kEcoLocations.length));
    });

    test('filters activities by location', () {
      final filters = ExploreFilters(
        currentQuery: 'Explore',
        activeFilters: const <String>{},
        categoryFilter: ExploreCategoryFilter.all,
        selectedLocation: 'Cornwall',
        selectedEcoTag: 'Any tag',
        sortOption: ExploreSortOption.ratingDesc,
      );

      final results = filters.filterActivities(kActivities);
      expect(results, hasLength(1));
      expect(results.single.title, 'Coastal Clean-Up Experience');
    });

    test('filters activities by eco tag', () {
      final filters = ExploreFilters(
        currentQuery: 'Explore',
        activeFilters: const <String>{},
        categoryFilter: ExploreCategoryFilter.all,
        selectedLocation: 'Anywhere',
        selectedEcoTag: 'workshop',
        sortOption: ExploreSortOption.ratingDesc,
      );

      final results = filters.filterActivities(kActivities);
      expect(results, hasLength(2));
      expect(
        results.map((item) => item.title).toSet(),
        equals({
          'Eco Cooking Workshop (Lisbon)',
          'Eco Cooking Workshop (Online)',
        }),
      );
    });

    test('sorts activities by rating desc', () {
      final filters = ExploreFilters(
        currentQuery: 'Explore',
        activeFilters: const <String>{},
        categoryFilter: ExploreCategoryFilter.all,
        selectedLocation: 'Anywhere',
        selectedEcoTag: 'Any tag',
        sortOption: ExploreSortOption.ratingDesc,
      );

      final results = filters.filterActivities(kActivities);
      expect(
        results.map((item) => item.title).toList(),
        equals([
          'Forest Replanting',
          'Coastal Clean-Up Experience',
          'Eco Cooking Workshop (Lisbon)',
          'Eco Cooking Workshop (Online)',
        ]),
      );
    });

    test('sorts activities by name asc', () {
      final filters = ExploreFilters(
        currentQuery: 'Explore',
        activeFilters: const <String>{},
        categoryFilter: ExploreCategoryFilter.all,
        selectedLocation: 'Anywhere',
        selectedEcoTag: 'Any tag',
        sortOption: ExploreSortOption.nameAsc,
      );

      final results = filters.filterActivities(kActivities);
      expect(
        results.map((item) => item.title).toList(),
        equals([
          'Coastal Clean-Up Experience',
          'Eco Cooking Workshop (Lisbon)',
          'Eco Cooking Workshop (Online)',
          'Forest Replanting',
        ]),
      );
    });

    test('returns empty list when filters exclude everything', () {
      final filters = ExploreFilters(
        currentQuery: 'Explore',
        activeFilters: const <String>{},
        categoryFilter: ExploreCategoryFilter.all,
        selectedLocation: 'Mars',
        selectedEcoTag: 'Any tag',
        sortOption: ExploreSortOption.ratingDesc,
      );

      final results = filters.filterActivities(kActivities);
      expect(results, isEmpty);
    });
  });
}
