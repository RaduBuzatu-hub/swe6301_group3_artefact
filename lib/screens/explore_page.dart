import 'package:flutter/material.dart';
import '../data/eco_locations.dart';
import 'search_page.dart';
import 'location_detail_page.dart';
import '../data/activities.dart';
import '../models/trip_entry.dart';
import '../utils/explore_filters.dart';
import 'activity_detail_page.dart';

/// Explore destinations/activities; supports search query, saved/booked toggles, and filters.
/// - Combines stay and activity data into a single filterable experience.
/// - Offers location, tag, and sort menus with quick chips.
/// - Navigates to stay/activity detail screens and returns selections.
class ExplorePage extends StatefulWidget {
  final String? query;
  final Set<String> savedKeys;
  final ValueChanged<EcoLocation> onToggleSave;
  final Set<String> bookedKeys;
  final void Function(EcoLocation, BookingDetails) onBookStay;
  final ValueChanged<EcoLocation> onUnbookStay;
  final ValueChanged<TripEntry>? onJoinTrip;
  final Future<DateTimeRange?> Function(BuildContext, List<DateTime>)?
      activityDateRangePicker;
  final VoidCallback? onViewTrips;
  final VoidCallback? onViewWallet;
  const ExplorePage({
    super.key,
    this.query,
    required this.savedKeys,
    required this.onToggleSave,
    required this.bookedKeys,
    required this.onBookStay,
    required this.onUnbookStay,
    this.onJoinTrip,
    this.activityDateRangePicker,
    this.onViewTrips,
    this.onViewWallet,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // Current query string shown in the search pill.
  late String _currentQuery;
  // Active filter ids used by the chip row.
  final Set<String> _activeFilters = {};
  // High-level category selection for stays vs activities.
  ExploreCategoryFilter _categoryFilter = ExploreCategoryFilter.all;
  // Selected location and eco tag from menus.
  String _selectedLocation = 'Anywhere';
  String _selectedEcoTag = 'Any tag';
  // Selected sort option for results.
  ExploreSortOption _sortOption = ExploreSortOption.ratingDesc;

  // Definition list for the horizontal filter chip row.
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
    // Apply incoming query and any category presets.
    final incoming = (widget.query ?? '').trim();
    if (!_applyCategoryPreset(incoming)) {
      _currentQuery = incoming.isEmpty ? 'Explore' : incoming;
    }
  }

  @override
  void didUpdateWidget(covariant ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state when the parent query changes.
    final incoming = (widget.query ?? '').trim();
    final previous = (oldWidget.query ?? '').trim();
    if (incoming != previous) {
      if (!_applyCategoryPreset(incoming)) {
        _currentQuery = incoming.isEmpty ? 'Explore' : incoming;
      }
    }
  }

  // Lowercased composite key to compare locations in saved/booked sets.
  String _locationKey(EcoLocation item) =>
      '${item.title.toLowerCase()}|${item.location.toLowerCase()}';

  // Build a sorted list of unique location labels for the filter menu.
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

  // Build a sorted list of unique eco tags for the filter menu.
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

  // Construct the ExploreFilters object used to filter both lists.
  ExploreFilters _buildFilters() {
    return ExploreFilters(
      currentQuery: _currentQuery,
      activeFilters: _activeFilters,
      categoryFilter: _categoryFilter,
      selectedLocation: _selectedLocation,
      selectedEcoTag: _selectedEcoTag,
      sortOption: _sortOption,
    );
  }

  // Reset all filter state back to defaults.
  void _resetFilters() {
    _currentQuery = 'Explore';
    _activeFilters.clear();
    _categoryFilter = ExploreCategoryFilter.all;
    _selectedLocation = 'Anywhere';
    _selectedEcoTag = 'Any tag';
    _sortOption = ExploreSortOption.ratingDesc;
  }

  // Apply special query presets (e.g., "activities") to filter state.
  bool _applyCategoryPreset(String? query) {
    final normalized = (query ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return false;
    switch (normalized) {
      case 'eco stays':
        _resetFilters();
        _categoryFilter = ExploreCategoryFilter.stays;
        return true;
      case 'activities':
        _resetFilters();
        _categoryFilter = ExploreCategoryFilter.activities;
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

  // Open the search page and update the current query.
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

  // Apply current filters to stay locations.
  List<EcoLocation> _filterResults() {
    return _buildFilters().filterLocations(kEcoLocations);
  }

  // Apply current filters to activities.
  List<ActivityItem> _filterActivities() {
    return _buildFilters().filterActivities(kActivities);
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
                      // Search pill opens the full SearchPage.
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
                      // Dropdown menus for category, location, eco tag, and sort.
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
                              items: ExploreCategoryFilter.values.map((e) => e.label).toList(),
                              onSelected: (value) {
                                setState(() {
                                  _categoryFilter = ExploreCategoryFilter.values
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
                      // Horizontal chip row for quick filter toggles.
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
                      // Empty state when nothing matches filters.
                      if (totalResults == 0)
                        _EmptyResults(
                          onClear: () {
                            setState(() {
                              _resetFilters();
                            });
                          },
                        ),
                      if (totalResults == 0) const SizedBox(height: 16),
                      // Featured full-width result card.
                      if (filteredLocations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ResultCard(
                            item: filteredLocations.first,
                            isFullWidth: true,
                            isSaved: widget.savedKeys
                                    .contains(_locationKey(filteredLocations.first)) &&
                                !widget.bookedKeys
                                    .contains(_locationKey(filteredLocations.first)),
                            isBooked: widget.bookedKeys
                                .contains(_locationKey(filteredLocations.first)),
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
                                    onBook: (details) =>
                                        widget.onBookStay(filteredLocations.first, details),
                                    onUnbook: () => widget.onUnbookStay(filteredLocations.first),
                                    onViewTrips: widget.onViewTrips,
                                    onViewWallet: widget.onViewWallet,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      // Remaining location cards rendered in a grid.
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
                                  isSaved: widget.savedKeys.contains(_locationKey(item)) &&
                                      !widget.bookedKeys.contains(_locationKey(item)),
                                  isBooked:
                                      widget.bookedKeys.contains(_locationKey(item)),
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
                                          onBook: (details) => widget.onBookStay(item, details),
                                          onUnbook: () => widget.onUnbookStay(item),
                                          onViewTrips: widget.onViewTrips,
                                          onViewWallet: widget.onViewWallet,
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
                        // Activity cards rendered in a grid.
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
                                          dateRangePicker: widget.activityDateRangePicker,
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

/// Toggleable chip used in the horizontal filter row.
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

/// Data holder for a filter option id + label.
class _FilterOption {
  final String id;
  final String label;
  const _FilterOption({required this.id, required this.label});
}

/// Popup menu wrapper used for category/location/tag filters.
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

/// Popup menu wrapper for sort options.
class _SortMenu extends StatelessWidget {
  final ExploreSortOption value;
  final ValueChanged<ExploreSortOption> onSelected;
  const _SortMenu({
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExploreSortOption>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return ExploreSortOption.values
            .map(
              (option) => PopupMenuItem<ExploreSortOption>(
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

/// Pill-style label used by filter menus.
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
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Icon(Icons.expand_more, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}

/// Empty state shown when filters return no results.
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

/// Card rendering for a single stay/location result.
class _ResultCard extends StatelessWidget {
  final EcoLocation item;
  final bool isFullWidth;
  final bool isSaved;
  final bool isBooked;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenDetail;
  const _ResultCard({
    required this.item,
    this.isFullWidth = true,
    required this.isSaved,
    this.isBooked = false,
    required this.onToggleSave,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final canSave = !isBooked;
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
                        onTap: canSave ? onToggleSave : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: canSave
                                ? (isSaved ? Colors.pinkAccent.shade100 : Colors.white)
                                : Colors.white70,
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

/// Card rendering for a single activity result.
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

/// Small badge used on images for category/tag.
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

/// Small text pill used for meta and price labels.
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
