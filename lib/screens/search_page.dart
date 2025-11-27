import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _popularSearches = const [
    'Low CO2 getaways',
    'No-flight trips',
    'Budget eco stays',
    'Forest hikes',
  ];
  final List<String> _suggestedLocations = const [
    'Cornwall',
    'Glamping',
    'Spain',
    'Beach',
    'Alps',
    'Bali',
  ];
  List<String> _recentSearches = [];

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

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_recentKey) ?? [];
    });
  }

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

  void _handleSubmit([String? value]) {
    final text = value ?? _controller.text;
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    _saveRecent(normalized);
    _controller.clear();
    Navigator.of(context).pop(normalized);
  }

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

  Widget _buildChips(List<String> items) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => ActionChip(
              backgroundColor: Colors.white.withOpacity(0.12),
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
              style: TextStyle(color: Colors.white),
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
                TextField(
                  controller: _controller,
                  onSubmitted: _handleSubmit,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Colors.white70,
                  decoration: InputDecoration(
                    hintText: 'Search eco-friendly trips',
                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () => setState(() => _controller.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.14),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                _buildSectionTitle('Recent searches'),
                if (_recentSearches.isEmpty)
                  const Text(
                    'No recent searches yet',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  _buildChips(_recentSearches),
                _buildSectionTitle('Popular searches'),
                _buildChips(_popularSearches),
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
