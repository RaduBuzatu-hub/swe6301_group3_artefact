import '../data/activities.dart';
import '../data/eco_locations.dart';

enum ExploreCategoryFilter { all, stays, activities }

extension ExploreCategoryFilterLabel on ExploreCategoryFilter {
  String get label {
    switch (this) {
      case ExploreCategoryFilter.all:
        return 'All';
      case ExploreCategoryFilter.stays:
        return 'Stays';
      case ExploreCategoryFilter.activities:
        return 'Activities';
    }
  }
}

enum ExploreSortOption { ratingDesc, nameAsc }

extension ExploreSortOptionLabel on ExploreSortOption {
  String get label {
    switch (this) {
      case ExploreSortOption.ratingDesc:
        return 'Rating';
      case ExploreSortOption.nameAsc:
        return 'Name A-Z';
    }
  }
}

class ExploreFilters {
  final String currentQuery;
  final Set<String> activeFilters;
  final ExploreCategoryFilter categoryFilter;
  final String selectedLocation;
  final String selectedEcoTag;
  final ExploreSortOption sortOption;

  const ExploreFilters({
    required this.currentQuery,
    required this.activeFilters,
    required this.categoryFilter,
    required this.selectedLocation,
    required this.selectedEcoTag,
    required this.sortOption,
  });

  List<EcoLocation> filterLocations(List<EcoLocation> locations) {
    if (categoryFilter == ExploreCategoryFilter.activities) return [];
    final q = currentQuery.toLowerCase().trim();
    final isDefaultQuery = q.isEmpty || q == 'explore' || q.contains('activit');
    final tokens = q.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

    bool matches(EcoLocation item) {
      if (isDefaultQuery) return true;
      final title = item.title.toLowerCase();
      final loc = item.location.toLowerCase();
      final tags = item.tags.map((t) => t.toLowerCase());
      final tagString = item.tags.map((t) => t.toLowerCase()).join(' ');

      if (title.contains(q) || loc.contains(q) || tagString.contains(q) || q.contains(loc)) {
        return true;
      }

      for (final token in tokens) {
        if (title.contains(token) || loc.contains(token) || tags.any((t) => t.contains(token))) {
          return true;
        }
      }
      return false;
    }

    final base = locations.where(matches).toList();
    final filtered = base
        .where(_passesLocationFilters)
        .where((item) => _matchesLocation(item.location))
        .where(
          (item) => _matchesEcoTag(
            tags: item.tags,
            meta: item.meta,
            title: item.title,
          ),
        )
        .toList();
    return _sortLocations(filtered);
  }

  List<ActivityItem> filterActivities(List<ActivityItem> activities) {
    if (categoryFilter == ExploreCategoryFilter.stays) return [];
    final q = currentQuery.toLowerCase().trim();
    final isDefaultQuery = q.isEmpty || q == 'explore' || q.contains('activit');
    final tokens = q.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

    bool matches(ActivityItem item) {
      if (isDefaultQuery) return true;
      final title = item.title.toLowerCase();
      final loc = item.location.toLowerCase();
      final tags = item.tags.map((t) => t.toLowerCase());
      final tagString = item.tags.map((t) => t.toLowerCase()).join(' ');
      final meta = item.meta.toLowerCase();

      if (title.contains(q) ||
          loc.contains(q) ||
          tagString.contains(q) ||
          q.contains(loc) ||
          meta.contains(q)) {
        return true;
      }

      for (final token in tokens) {
        if (title.contains(token) ||
            loc.contains(token) ||
            tags.any((t) => t.contains(token)) ||
            meta.contains(token)) {
          return true;
        }
      }
      return false;
    }

    final base = activities.where(matches).toList();
    final filtered = base
        .where(_passesActivityFilters)
        .where((item) => _matchesLocation(item.location))
        .where(
          (item) => _matchesEcoTag(
            tags: item.tags,
            meta: item.meta,
            title: item.title,
          ),
        )
        .toList();
    return _sortActivities(filtered);
  }

  bool _matchesLocation(String location) {
    if (selectedLocation == 'Anywhere') return true;
    final selected = selectedLocation.toLowerCase();
    final loc = location.toLowerCase();
    return loc.contains(selected) || selected.contains(loc);
  }

  bool _matchesEcoTag({
    required List<String> tags,
    required String meta,
    required String title,
  }) {
    if (selectedEcoTag == 'Any tag') return true;
    final selected = selectedEcoTag.toLowerCase();
    return tags.any((tag) => tag.toLowerCase().contains(selected)) ||
        meta.toLowerCase().contains(selected) ||
        title.toLowerCase().contains(selected);
  }

  int? _extractPriceValue(String price) {
    final match = RegExp(r'(\\d+)').firstMatch(price.replaceAll(',', ''));
    return match != null ? int.tryParse(match.group(1) ?? '') : null;
  }

  bool _isBudgetPrice(String price) {
    final value = _extractPriceValue(price);
    return value == null ? false : value <= 250;
  }

  bool _passesLocationFilters(EcoLocation item) {
    for (final f in activeFilters) {
      switch (f) {
        case 'low_co2':
          if (!_isLowCo2Location(item)) return false;
          break;
        case 'budget':
          if (!_isBudgetPrice(item.price)) return false;
          break;
        case 'nature':
          if (!_isNatureLocation(item)) return false;
          break;
        case 'beach':
          if (!_isBeachLocation(item)) return false;
          break;
        case 'city':
          if (!_isCityLocation(item)) return false;
          break;
        case 'adventure':
          if (!_isAdventureLocation(item)) return false;
          break;
        case 'island':
          if (!_isIslandLocation(item)) return false;
          break;
        case 'vegan':
          if (!_isVeganLocation(item)) return false;
          break;
      }
    }
    return true;
  }

  bool _passesActivityFilters(ActivityItem item) {
    for (final f in activeFilters) {
      switch (f) {
        case 'low_co2':
          if (!_isLowCo2Activity(item)) return false;
          break;
        case 'budget':
          if (!_isBudgetPrice(item.price)) return false;
          break;
        case 'nature':
          if (!_isNatureActivity(item)) return false;
          break;
        case 'beach':
          if (!_isBeachActivity(item)) return false;
          break;
        case 'city':
          if (!_isCityActivity(item)) return false;
          break;
        case 'adventure':
          if (!_isAdventureActivity(item)) return false;
          break;
        case 'island':
          if (!_isIslandActivity(item)) return false;
          break;
        case 'vegan':
          if (!_isVeganActivity(item)) return false;
          break;
      }
    }
    return true;
  }

  List<EcoLocation> _sortLocations(List<EcoLocation> items) {
    final list = [...items];
    switch (sortOption) {
      case ExploreSortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ExploreSortOption.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return list;
  }

  List<ActivityItem> _sortActivities(List<ActivityItem> items) {
    final list = [...items];
    switch (sortOption) {
      case ExploreSortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ExploreSortOption.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return list;
  }

  bool _isLowCo2Location(EcoLocation item) {
    final meta = item.meta.toLowerCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    return tags.contains('train') ||
        tags.contains('eco') ||
        tags.contains('budget') ||
        meta.contains('solar') ||
        meta.contains('local') ||
        meta.contains('bike') ||
        meta.contains('vegan');
  }

  bool _isNatureLocation(EcoLocation item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    final meta = item.meta.toLowerCase();
    return tags.any((t) => ['sea', 'lake', 'mountain', 'forest', 'island', 'lodge'].contains(t)) ||
        meta.contains('sea') ||
        meta.contains('lake') ||
        meta.contains('mountain') ||
        meta.contains('forest');
  }

  bool _isBeachLocation(EcoLocation item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    final meta = item.meta.toLowerCase();
    final loc = item.location.toLowerCase();
    return tags.any((t) => ['sea', 'beach', 'coast', 'island', 'cove'].contains(t)) ||
        meta.contains('sea') ||
        meta.contains('beach') ||
        meta.contains('coast') ||
        meta.contains('cove') ||
        loc.contains('beach');
  }

  bool _isCityLocation(EcoLocation item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    final loc = item.location.toLowerCase();
    return loc.contains('london') || tags.contains('london') || tags.contains('city') || tags.contains('hostel');
  }

  bool _isAdventureLocation(EcoLocation item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    final meta = item.meta.toLowerCase();
    return tags.any((t) => ['mountain', 'forest', 'lake', 'alps', 'outdoor'].contains(t)) ||
        meta.contains('hike') ||
        meta.contains('sauna') ||
        meta.contains('glacier') ||
        meta.contains('outdoor');
  }

  bool _isIslandLocation(EcoLocation item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    final loc = item.location.toLowerCase();
    return tags.contains('island') || tags.contains('bali') || loc.contains('island') || loc.contains('bali');
  }

  bool _isVeganLocation(EcoLocation item) {
    final meta = item.meta.toLowerCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    return meta.contains('vegan') || tags.contains('vegan');
  }

  bool _isLowCo2Activity(ActivityItem item) {
    final meta = item.meta.toLowerCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    return meta.contains('free') ||
        tags.contains('outdoor') ||
        tags.contains('clean-up') ||
        tags.contains('tree planting') ||
        tags.contains('forest') ||
        tags.contains('bike') ||
        tags.contains('walk');
  }

  bool _isNatureActivity(ActivityItem item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    return tags.any((t) => ['beach', 'forest', 'outdoor', 'mountain'].contains(t));
  }

  bool _isBeachActivity(ActivityItem item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    final loc = item.location.toLowerCase();
    return tags.contains('beach') || loc.contains('beach') || loc.contains('coast') || loc.contains('sea');
  }

  bool _isCityActivity(ActivityItem item) {
    final loc = item.location.toLowerCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    return loc.contains('lisbon') || loc.contains('london') || tags.contains('city');
  }

  bool _isAdventureActivity(ActivityItem item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toList();
    return tags.any((t) => ['outdoor', 'forest', 'clean-up', 'tree planting'].contains(t));
  }

  bool _isIslandActivity(ActivityItem item) {
    final loc = item.location.toLowerCase();
    return loc.contains('island') || loc.contains('bali');
  }

  bool _isVeganActivity(ActivityItem item) {
    final meta = item.meta.toLowerCase();
    final title = item.title.toLowerCase();
    return meta.contains('vegan') || title.contains('vegan');
  }
}
