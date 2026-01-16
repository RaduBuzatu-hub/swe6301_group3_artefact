import 'package:flutter/material.dart';
import '../data/eco_locations.dart';
import 'search_page.dart';
import 'location_detail_page.dart';
import '../data/activities.dart';
import '../models/trip_entry.dart';
import 'activity_detail_page.dart';

/// Explore destinations/activities; supports search query, saved/booked toggles, and filters.
class ExplorePage extends StatefulWidget {
  final String? query;
  final Set<String> savedKeys;
  final ValueChanged<EcoLocation> onToggleSave;
  final Set<String> bookedKeys;
  final ValueChanged<EcoLocation> onBookStay;
  final ValueChanged<EcoLocation> onUnbookStay;
  final ValueChanged<TripEntry>? onJoinTrip;
  final VoidCallback? onViewTrips;
  const ExplorePage({
    super.key,
    this.query,
    required this.savedKeys,
    required this.onToggleSave,
    required this.bookedKeys,
    required this.onBookStay,
    required this.onUnbookStay,
    this.onJoinTrip,
    this.onViewTrips,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late String _currentQuery;
  final Set<String> _activeFilters = {};
  _CategoryFilter _categoryFilter = _CategoryFilter.all;
  String _selectedLocation = 'Anywhere';
  String _selectedEcoTag = 'Any tag';
  _SortOption _sortOption = _SortOption.ratingDesc;

  static const List<_FilterOption> _filterOptions = [
    _FilterOption(id: 'low_co2', label: 'Low CO₂ only'),
    _FilterOption(id: 'budget', label: '≤ GBP250'),
    _FilterOption(id: 'nature', label: 'Nature escapes'),
    _FilterOption(id: 'beach', label: 'Beach & coast'),
    _FilterOption(id: 'city', label: 'City breaks'),
    _FilterOption(id: 'adventure', label: 'Outdoor adventure'),
    _FilterOption(id: 'island', label: 'Island vibes'),
    _FilterOption(id: 'vegan', label: 'Vegan friendly'),
  ];

  @override
  void initState() {
    super.initState();
    final incoming = (widget.query ?? '').trim();
    if (!_applyCategoryPreset(incoming)) {
      _currentQuery = incoming.isEmpty ? 'Explore' : incoming;
    }
  }

  @override
  void didUpdateWidget(covariant ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = (widget.query ?? '').trim();
    final previous = (oldWidget.query ?? '').trim();
    if (incoming != previous) {
      if (!_applyCategoryPreset(incoming)) {
        _currentQuery = incoming.isEmpty ? 'Explore' : incoming;
      }
    }
  }

  String _locationKey(EcoLocation item) =>
      '${item.title.toLowerCase()}|${item.location.toLowerCase()}';

  List<String> get _locationOptions {
    final options = <String>{};
    for (final location in kEcoLocations) {
      options.add(location.location);
    }
    for (final activity in kActivities) {
      options.add(activity.location);
    }
    final list = options.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['Anywhere', ...list];
  }

  List<String> get _ecoTagOptions {
    final options = <String>{};
    for (final location in kEcoLocations) {
      options.addAll(location.tags);
    }
    for (final activity in kActivities) {
      options.addAll(activity.tags);
    }
    final list = options.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['Any tag', ...list];
  }

  bool _matchesLocation(String location) {
    if (_selectedLocation == 'Anywhere') return true;
    final selected = _selectedLocation.toLowerCase();
    final loc = location.toLowerCase();
    return loc.contains(selected) || selected.contains(loc);
  }

  bool _matchesEcoTag({
    required List<String> tags,
    required String meta,
    required String title,
  }) {
    if (_selectedEcoTag == 'Any tag') return true;
    final selected = _selectedEcoTag.toLowerCase();
    return tags.any((tag) => tag.toLowerCase().contains(selected)) ||
        meta.toLowerCase().contains(selected) ||
        title.toLowerCase().contains(selected);
  }

  void _resetFilters() {
    _currentQuery = 'Explore';
    _activeFilters.clear();
    _categoryFilter = _CategoryFilter.all;
    _selectedLocation = 'Anywhere';
    _selectedEcoTag = 'Any tag';
    _sortOption = _SortOption.ratingDesc;
  }

  bool _applyCategoryPreset(String? query) {
    final normalized = (query ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return false;
    switch (normalized) {
      case 'eco stays':
        _resetFilters();
        _categoryFilter = _CategoryFilter.stays;
        return true;
      case 'activities':
        _resetFilters();
        _categoryFilter = _CategoryFilter.activities;
        return true;
      case 'nature':
        _resetFilters();
        _activeFilters.add('nature');
        return true;
      case 'local tours':
        _resetFilters();
        _currentQuery = 'local';
        return true;
    }
    return false;
  }

  int? _extractPriceValue(String price) {
    final match = RegExp(r'(\\d+)').firstMatch(price.replaceAll(',', ''));
    return match != null ? int.tryParse(match.group(1) ?? '') : null;
  }

  bool _isBudgetPrice(String price) {
    final value = _extractPriceValue(price);
    return value == null ? false : value <= 250;
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

  Future<void> _openSearch(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
    if (result != null) {
      setState(() {
        final normalized = result.trim();
        _currentQuery = normalized.isEmpty ? 'Explore' : normalized;
      });
    }
  }

  List<EcoLocation> _filterResults() {
    if (_categoryFilter == _CategoryFilter.activities) return [];
    final q = _currentQuery.toLowerCase().trim();
    final baseList = kEcoLocations;
    final isDefaultQuery = q.isEmpty || q == 'explore' || q.contains('activit');

    final tokens = q.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

    bool matches(EcoLocation item) {
      if (isDefaultQuery) return true;
      final title = item.title.toLowerCase();
      final loc = item.location.toLowerCase();
      final tags = item.tags.map((t) => t.toLowerCase());
      final tagString = item.tags.map((t) => t.toLowerCase()).join(' ');

      // full query match (either direction)
      if (title.contains(q) || loc.contains(q) || tagString.contains(q) || q.contains(loc)) {
        return true;
      }

      // token match
      for (final token in tokens) {
        if (title.contains(token) || loc.contains(token) || tags.any((t) => t.contains(token))) {
          return true;
        }
      }
      return false;
    }

    final base = baseList.where(matches).toList();
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

  List<ActivityItem> _filterActivities() {
    if (_categoryFilter == _CategoryFilter.stays) return [];
    final q = _currentQuery.toLowerCase().trim();
    final all = kActivities;
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

    final base = all.where(matches).toList();
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

  List<EcoLocation> _sortLocations(List<EcoLocation> items) {
    final list = [...items];
    switch (_sortOption) {
      case _SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return list;
  }

  List<ActivityItem> _sortActivities(List<ActivityItem> items) {
    final list = [...items];
    switch (_sortOption) {
      case _SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return list;
  }

  bool _passesLocationFilters(EcoLocation item) {
    for (final f in _activeFilters) {
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
    for (final f in _activeFilters) {
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

  @override
  Widget build(BuildContext context) {
    final filteredLocations = _filterResults();
    final filteredActivities = _filterActivities();
    final totalResults = filteredLocations.length + filteredActivities.length;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black38,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$totalResults eco-friendly results',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    blurRadius: 5,
                    color: Colors.black38,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFB388FF),
                Color(0xFF7E57C2),
                Color(0xFF5E35B1),
                Color(0xFF311B92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB388FF),
              Color(0xFF7E57C2),
              Color(0xFF5E35B1),
              Color(0xFF311B92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _openSearch(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentQuery.isEmpty || _currentQuery == 'Explore'
                                      ? 'Search eco-friendly trips'
                                      : _currentQuery,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (_currentQuery.isNotEmpty && _currentQuery != 'Explore')
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _resetFilters();
                                    });
                                  },
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FilterMenu(
                              label: 'Category',
                              value: _categoryFilter.label,
                              items: _CategoryFilter.values.map((e) => e.label).toList(),
                              onSelected: (value) {
                                setState(() {
                                  _categoryFilter = _CategoryFilter.values
                                      .firstWhere((e) => e.label == value);
                                });
                              },
                            ),
                            _FilterMenu(
                              label: 'Location',
                              value: _selectedLocation,
                              items: _locationOptions,
                              onSelected: (value) {
                                setState(() {
                                  _selectedLocation = value;
                                });
                              },
                            ),
                            _FilterMenu(
                              label: 'Eco tag',
                              value: _selectedEcoTag,
                              items: _ecoTagOptions,
                              onSelected: (value) {
                                setState(() {
                                  _selectedEcoTag = value;
                                });
                              },
                            ),
                            _SortMenu(
                              value: _sortOption,
                              onSelected: (value) {
                                setState(() {
                                  _sortOption = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < _filterOptions.length; i++) ...[
                                _SelectableFilterChip(
                                  label: _filterOptions[i].label,
                                  selected: _activeFilters.contains(_filterOptions[i].id),
                                  onTap: () {
                                    setState(() {
                                      if (_activeFilters.contains(_filterOptions[i].id)) {
                                        _activeFilters.remove(_filterOptions[i].id);
                                      } else {
                                        _activeFilters.add(_filterOptions[i].id);
                                      }
                                    });
                                  },
                                ),
                                if (i != _filterOptions.length - 1) const SizedBox(width: 10),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (totalResults == 0)
                        _EmptyResults(
                          onClear: () {
                            setState(() {
                              _resetFilters();
                            });
                          },
                        ),
                      if (totalResults == 0) const SizedBox(height: 16),
                      if (filteredLocations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ResultCard(
                            item: filteredLocations.first,
                            isFullWidth: true,
                            isSaved:
                                widget.savedKeys.contains(_locationKey(filteredLocations.first)),
                            onToggleSave: () => widget.onToggleSave(filteredLocations.first),
                            onOpenDetail: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LocationDetailPage(
                                    location: filteredLocations.first,
                                    isSaved: widget.savedKeys
                                        .contains(_locationKey(filteredLocations.first)),
                                    isBooked: widget.bookedKeys
                                        .contains(_locationKey(filteredLocations.first)),
                                    onToggleSave: () =>
                                        widget.onToggleSave(filteredLocations.first),
                                    onBook: () => widget.onBookStay(filteredLocations.first),
                                    onUnbook: () => widget.onUnbookStay(filteredLocations.first),
                                    onViewTrips: widget.onViewTrips,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (filteredLocations.length > 1)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final item in filteredLocations.skip(1))
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
                                child: _ResultCard(
                                  item: item,
                                  isFullWidth: false,
                                  isSaved: widget.savedKeys.contains(_locationKey(item)),
                                  onToggleSave: () => widget.onToggleSave(item),
                                  onOpenDetail: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LocationDetailPage(
                                          location: item,
                                          isSaved: widget.savedKeys.contains(_locationKey(item)),
                                          onToggleSave: () => widget.onToggleSave(item),
                                          isBooked:
                                              widget.bookedKeys.contains(_locationKey(item)),
                                          onBook: () => widget.onBookStay(item),
                                          onUnbook: () => widget.onUnbookStay(item),
                                          onViewTrips: widget.onViewTrips,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      if (filteredActivities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Activities & events',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final activity in filteredActivities)
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
                                child: _ActivityCard(
                                  item: activity,
                                  onOpenDetail: () async {
                                    final entry = TripEntry(
                                      title: activity.title,
                                      subtitle: activity.location,
                                      location: activity.location,
                                      price: activity.price,
                                      assetPath: activity.assetPath,
                                      imageUrl: null,
                                      date: null,
                                      isPast: false,
                                    );
                                    final result = await Navigator.of(context).push<TripEntry>(
                                      MaterialPageRoute(
                                        builder: (_) => ActivityDetailPage(
                                          entry: entry,
                                          tagPrimary:
                                              activity.tags.isNotEmpty ? activity.tags.first : '',
                                          tagSecondary:
                                              activity.tags.length > 1 ? activity.tags[1] : '',
                                        ),
                                      ),
                                    );
                                    if (result != null) {
                                      widget.onJoinTrip?.call(result);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SelectableFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectableFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.white.withValues(alpha: selected ? 0.22 : 0.12);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(18),
          border: selected ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2) : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String id;
  final String label;
  const _FilterOption({required this.id, required this.label});
}

enum _CategoryFilter { all, stays, activities }

extension _CategoryFilterLabel on _CategoryFilter {
  String get label {
    switch (this) {
      case _CategoryFilter.all:
        return 'All';
      case _CategoryFilter.stays:
        return 'Stays';
      case _CategoryFilter.activities:
        return 'Activities';
    }
  }
}

enum _SortOption { ratingDesc, nameAsc }

extension _SortOptionLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.ratingDesc:
        return 'Rating';
      case _SortOption.nameAsc:
        return 'Name A-Z';
    }
  }
}

class _FilterMenu extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onSelected;
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return items
            .map(
              (item) => PopupMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList();
      },
      child: _FilterPill(
        label: label,
        value: value,
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final _SortOption value;
  final ValueChanged<_SortOption> onSelected;
  const _SortMenu({
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortOption>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return _SortOption.values
            .map(
              (option) => PopupMenuItem<_SortOption>(
                value: option,
                child: Text(option.label),
              ),
            )
            .toList();
      },
      child: _FilterPill(
        label: 'Sort',
        value: value.label,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final String value;
  const _FilterPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different category, location, or eco tag.',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
            child: const Text(
              'Clear filters',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final EcoLocation item;
  final bool isFullWidth;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenDetail;
  const _ResultCard({
    required this.item,
    this.isFullWidth = true,
    required this.isSaved,
    required this.onToggleSave,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(isFullWidth ? 18 : 16),
      onTap: onOpenDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isFullWidth ? 18 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(isFullWidth ? 18 : 16)),
              child: AspectRatio(
                aspectRatio: isFullWidth ? 3 / 2 : 1.1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Badge(label: item.tags.isNotEmpty ? item.tags.first : 'Eco stay'),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: () {
                          onToggleSave();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.pinkAccent.shade100 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.location,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaBullet(text: item.meta),
                      _MetaBullet(text: item.price),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback onOpenDetail;
  const _ActivityCard({required this.item, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    Widget buildImage() {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        return Image.network(
          item.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
          ),
        );
      }
      if (item.assetPath != null && item.assetPath!.isNotEmpty) {
        return Image.asset(
          item.assetPath!,
          fit: BoxFit.cover,
        );
      }
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpenDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: buildImage(),
                    ),
                    if (item.tags.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _Badge(label: item.tags.first),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaBullet(text: item.meta),
                      _MetaBullet(text: item.price),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaBullet extends StatelessWidget {
  final String text;
  const _MetaBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
