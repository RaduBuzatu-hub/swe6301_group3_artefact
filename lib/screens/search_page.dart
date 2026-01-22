import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Search page UI that collects a query and returns it via Navigator.pop.
/// - Persists recent searches locally with SharedPreferences.
/// - Surfaces popular and suggested terms for quick selection.
/// - Normalizes input before saving/returning it.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controller for the search input field.
  final TextEditingController _controller = TextEditingController();
  // Curated example terms to help users start a search.
  final List<String> _popularSearches = const [
    'Low CO2 getaways',
    'No-flight trips',
    'Budget eco stays',
    'Forest hikes',
  ];
  // Simple list of suggested destinations/keywords.
  final List<String> _suggestedLocations = const [
    'Cornwall',
    'Glamping',
    'Spain',
    'Beach',
    'Alps',
    'Bali',
  ];
  // In-memory copy of recent searches loaded from preferences.
  List<String> _recentSearches = [];

  // SharedPreferences key for storing recent searches.
  static const String _recentKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Load recent searches on first build.
  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_recentKey) ?? [];
    });
  }

  // Save a term, de-duplicate, and cap the list length.
  Future<void> _saveRecent(String term) async {
    final normalized = term.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(normalized);
      _recentSearches.insert(0, normalized);
      if (_recentSearches.length > 8) {
        _recentSearches = _recentSearches.sublist(0, 8);
      }
    });
    await prefs.setStringList(_recentKey, _recentSearches);
  }

  // Normalize input, persist it, and return the value to the caller.
  void _handleSubmit([String? value]) {
    final text = value ?? _controller.text;
    final normalized = text.trim();
    if (normalized.isEmpty) {
      Navigator.of(context).pop('');
      return;
    }
    _saveRecent(normalized);
    _controller.clear();
    Navigator.of(context).pop(normalized);
  }

  // Section header styling.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  // Render a group of tappable chips for quick search shortcuts.
  Widget _buildChips(List<String> items) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => ActionChip(
              backgroundColor: const Color(0x99311B92), // semi-transparent purple
              label: Text(
                item,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              onPressed: () => _handleSubmit(item),
            ),
          )
          .toList(),
    );
  }

  // Render a vertical list of suggested locations.
  Widget _buildSuggestionList() {
    return Column(
      children: _suggestedLocations
          .map(
            (loc) => ListTile(
              leading: const Icon(Icons.search, color: Colors.white70),
              title: Text(
                loc,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _handleSubmit(loc),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFF7DFA5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search input with clear button and submit handling.
                TextField(
                  controller: _controller,
                  onSubmitted: _handleSubmit,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: Color(0xFFF7DFA5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Color(0xFFF7DFA5),
                  decoration: InputDecoration(
                    hintText: 'Search eco-friendly trips',
                    hintStyle: const TextStyle(
                      color: Color(0xFFF7DFA5),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFF7DFA5)),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFFF7DFA5)),
                            onPressed: () => setState(() => _controller.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.14),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                // Recent search history (persisted in SharedPreferences).
                _buildSectionTitle('Recent searches'),
                if (_recentSearches.isEmpty)
                  const Text(
                    'No recent searches yet',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  _buildChips(_recentSearches),
                // Curated popular terms for quick exploration.
                _buildSectionTitle('Popular searches'),
                _buildChips(_popularSearches),
                // Suggested locations as a scrollable list.
                _buildSectionTitle('Suggested'),
                _buildSuggestionList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
