class TripEntry {
  final String title;
  final String subtitle;
  final String location;
  final String price;
  final String? assetPath;
  final String? imageUrl;
  final DateTime? date;
  final bool isPast;
  const TripEntry({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.price,
    this.assetPath,
    this.imageUrl,
    this.date,
    this.isPast = false,
  });
}
