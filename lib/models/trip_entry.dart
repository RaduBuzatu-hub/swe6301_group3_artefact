/// UI-friendly model used across lists/detail screens to describe a trip/activity.
/// - Accepts either local [assetPath] or remote [imageUrl] for imagery.
/// - Holds optional date range for bookings or joined activities.
/// - Used for saved/booked collections and handoffs between screens.
class TripEntry {
  final String title;
  final String subtitle;
  final String location;
  final String price;
  final String? assetPath;
  final String? imageUrl;
  final DateTime? date;
  final DateTime? endDate;
  final bool isPast;
  const TripEntry({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.price,
    this.assetPath,
    this.imageUrl,
    this.date,
    this.endDate,
    this.isPast = false,
  });
}
