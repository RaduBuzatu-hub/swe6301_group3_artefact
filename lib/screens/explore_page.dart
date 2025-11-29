import 'package:flutter/material.dart';
import '../data/eco_locations.dart';
import 'search_page.dart';
import 'location_detail_page.dart';
import '../data/activities.dart';
import '../models/trip_entry.dart';
import 'activity_detail_page.dart';

class ExplorePage extends StatefulWidget {
  final String? query;
  final Set<String> savedKeys;
  final ValueChanged<EcoLocation> onToggleSave;
  final Set<String> bookedKeys;
  final ValueChanged<EcoLocation> onBookStay;
  final ValueChanged<TripEntry>? onJoinTrip;
  final VoidCallback? onViewTrips;
  const ExplorePage({
    super.key,
    this.query,
    required this.savedKeys,
    required this.onToggleSave,
    required this.bookedKeys,
    required this.onBookStay,
    this.onJoinTrip,
    this.onViewTrips,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late String _currentQuery;
  final Set<String> _activeFilters = {};

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
    _currentQuery = (widget.query ?? '').isEmpty ? 'Explore' : widget.query!;
  }

  @override
  void didUpdateWidget(covariant ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = (widget.query ?? '').isEmpty ? 'Explore' : widget.query!;
    if (incoming != _currentQuery) {
      _currentQuery = incoming;
    }
  }

  String _locationKey(EcoLocation item) =>
      '${item.title.toLowerCase()}|${item.location.toLowerCase()}';

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
    final q = _currentQuery.toLowerCase().trim();
    final baseList = kEcoLocations;
    if (q.isEmpty || q == 'explore') return baseList;
    if (q.contains('activit')) return baseList;

    final tokens = q.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

    bool matches(EcoLocation item) {
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

    return base.where(_passesLocationFilters).toList();
  }

  List<ActivityItem> _filterActivities() {
    final q = _currentQuery.toLowerCase().trim();
    final all = kActivities;
    if (q.isEmpty || q == 'explore') return all;
    if (q.contains('activit')) return all;

    final tokens = q.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

    bool matches(ActivityItem item) {
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
    return base.where(_passesActivityFilters).toList();
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
                                      _currentQuery = 'Explore';
                                      _activeFilters.clear();
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
