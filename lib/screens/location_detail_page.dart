import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/eco_locations.dart';
import '../utils/available_dates.dart';

/// Booking summary passed back to callers after a stay is booked.
class BookingDetails {
  final DateTimeRange range;
  final int nightlyRate;
  final int nights;
  final int total;

  const BookingDetails({
    required this.range,
    required this.nightlyRate,
    required this.nights,
    required this.total,
  });
}

/// Location detail page used for both saved and booked contexts.
/// - Supports saving/un-saving the stay to local trips.
/// - Handles booking flow with wallet balance checks.
/// - Returns booking details via callbacks.
class LocationDetailPage extends StatefulWidget {
  final EcoLocation location;
  final bool isSaved;
  final bool isBooked;
  final VoidCallback onToggleSave;
  final ValueChanged<BookingDetails> onBook;
  final VoidCallback onUnbook;
  final VoidCallback? onViewTrips;
  final VoidCallback? onViewWallet;
  const LocationDetailPage({
    super.key,
    required this.location,
    required this.isSaved,
    required this.isBooked,
    required this.onToggleSave,
    required this.onBook,
    required this.onUnbook,
    this.onViewTrips,
    this.onViewWallet,
  });

  @override
  State<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends State<LocationDetailPage> {
  // Local UI state mirrors saved/booking status.
  late bool _saved;
  late bool _booked;
  // Precomputed available dates used by the date picker.
  late List<DateTime> _availableDates;
  // Flat nightly rate used for pricing calculations.
  static const int _nightlyRate = 150;

  @override
  void initState() {
    super.initState();
    // Seed initial state and available dates.
    _saved = widget.isSaved && !widget.isBooked;
    _booked = widget.isBooked;
    _availableDates = buildAvailableDates(
      seed: '${widget.location.title}|${widget.location.location}',
      count: 8,
      rangeDays: 60,
    );
  }

  // Toggle saved state unless the stay is already booked.
  void _handleToggleSave() {
    if (_booked) return;
    widget.onToggleSave();
    setState(() {
      _saved = !_saved;
    });
  }

  // Fetch wallet balance from Firestore (returns 0 on failure).
  Future<int> _fetchWalletBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('wallets').doc(uid).get();
      final data = doc.data();
      return (data?['balance'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // Attempt to debit the wallet by [amount]; returns success/failure.
  Future<bool> _chargeWallet(int amount) async {
    if (amount <= 0) return true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final walletRef = FirebaseFirestore.instance.collection('wallets').doc(uid);
    try {
      return await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(walletRef);
        final data = snapshot.data();
        final current = (data?['balance'] as num?)?.toInt() ?? 0;
        if (current < amount) {
          return false;
        }
        transaction.set(
          walletRef,
          {
            'balance': current - amount,
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  // Confirm pricing with the user and optionally route to wallet top-up.
  Future<bool> _confirmCost({
    required int nights,
    required int total,
    required int balance,
  }) async {
    final hasFunds = balance >= total;
    final theme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.primaryContainer,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(hasFunds ? 'Confirm booking' : 'Insufficient funds'),
          content: Text(
            '£$_nightlyRate per night × $nights '
            '${nights == 1 ? 'night' : 'nights'} = £$total\n'
            'Wallet balance: £$balance',
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.onPrimaryContainer.withValues(alpha: 0.9),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            if (hasFunds)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Book for £$total'),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                  widget.onViewWallet?.call();
                },
                child: const Text('Add funds'),
              ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Main booking flow: pick dates, confirm cost, charge wallet, persist booking.
  Future<void> _handleBook() async {
    if (_booked) {
      widget.onUnbook();
      setState(() {
        _booked = false;
      });
      return;
    }
    final selectedRange = await showPricedDateRangePicker(
      context: context,
      availableDates: _availableDates,
      nightlyRate: _nightlyRate,
      currencyLabel: '£',
      helpText: 'Select available dates',
    );
    if (selectedRange == null || !mounted) return;
    final nights = calculateNights(selectedRange.start, selectedRange.end);
    final total = nights * _nightlyRate;
    final balance = await _fetchWalletBalance();
    if (!mounted) return;
    final canBook = await _confirmCost(
      nights: nights,
      total: total,
      balance: balance,
    );
    if (!canBook || !mounted) return;
    final charged = await _chargeWallet(total);
    if (!mounted) return;
    if (!charged) {
      final updatedBalance = await _fetchWalletBalance();
      if (!mounted) return;
      if (updatedBalance < total) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Insufficient funds. Please add to your wallet.')),
        );
        widget.onViewWallet?.call();
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Unable to charge the wallet right now.')),
        );
      }
      return;
    }
    widget.onBook(
      BookingDetails(
        range: selectedRange,
        nightlyRate: _nightlyRate,
        nights: nights,
        total: total,
      ),
    );
    setState(() {
      _booked = true;
      _saved = false;
    });
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Booking confirmed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.location.title} • ${widget.location.location}'),
              const SizedBox(height: 12),
              _InvoiceRow(label: 'Dates', value: _formatRange(selectedRange)),
              _InvoiceRow(label: 'Nights', value: '$nights'),
              _InvoiceRow(label: 'Rate', value: 'Aś$_nightlyRate / night'),
              _InvoiceRow(label: 'Total', value: 'Aś$total'),
              const SizedBox(height: 12),
              const Text(
                'Your booking is active. You can manage it in Trips.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.location;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_saved ? Icons.favorite : Icons.favorite_border),
            color: Colors.white,
            disabledColor: Colors.white70,
            // Disable saving if already booked.
            onPressed: _booked ? null : _handleToggleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image for the location.
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(
                l.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and headline metadata.
                  Text(
                    l.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF2E2A68),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.location,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  // Meta/tag pills for location details.
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TagChip(label: l.meta),
                      _TagChip(label: l.price),
                      for (final tag in l.tags) _TagChip(label: tag),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description section.
                  const Text(
                    'About this stay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Discover an eco-friendly stay that aligns with low-impact travel. Enjoy local experiences, support sustainable hosts, and explore nearby nature spots.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Booking and save CTAs.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(_booked ? Icons.cancel : Icons.book_online),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _handleBook,
                        label: Text(
                          _booked ? 'Cancel booking' : 'Book this stay',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: Icon(_saved ? Icons.favorite : Icons.favorite_border),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A148C),
                          side: const BorderSide(color: Color(0xFF4A148C), width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _booked ? null : _handleToggleSave,
                        label: Text(
                          _booked ? 'Already booked' : (_saved ? 'Saved' : 'Save to trips'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      if (_booked && widget.onViewTrips != null) ...[
                        const SizedBox(height: 10),
                        // Shortcut back to Trips tab after booking.
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A148C),
                            side: const BorderSide(color: Color(0xFF4A148C), width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: widget.onViewTrips,
                          child: const Text(
                            'View in Trips',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
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

/// Small pill used for location meta and tags.
class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E2A68),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Format a DateTimeRange for display in booking confirmation.
String _formatRange(DateTimeRange range) {
  String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  return '${formatDate(range.start)} to ${formatDate(range.end)}';
}

/// Two-column row used in the confirmation invoice.
class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }
}
