import 'package:flutter/material.dart';
import '../models/trip_entry.dart';
import 'available_dates.dart';

/// Booking helpers for day keys, validation, slot math, and ledger updates.

/// Stable integer key for a calendar day (YYYYMMDD).
int bookingDayKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

/// Build a set of valid day keys from available dates.
Set<int> buildAllowedDayKeys(List<DateTime> availableDates) {
  return availableDates.map((date) => bookingDayKey(dateOnly(date))).toSet();
}

/// Validation rules for stay and activity bookings.
class BookingValidator {
  static String? validateRequiredFields({
    required String title,
    required String location,
  }) {
    if (title.trim().isEmpty || location.trim().isEmpty) {
      return 'Title and location are required.';
    }
    return null;
  }

  static String? validateRange({
    required DateTimeRange? range,
    required Set<int> allowedDays,
  }) {
    if (range == null) {
      return 'Select a date range.';
    }
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);
    if (end.isBefore(start)) {
      return 'End date must be on or after start date.';
    }
    final normalized = DateTimeRange(start: start, end: end);
    if (!isRangeAvailable(normalized, allowedDays)) {
      return 'Selected range includes unavailable dates.';
    }
    return null;
  }

  static String? validateTotals({
    required DateTimeRange range,
    required int nightlyRate,
    required int nights,
    required int total,
  }) {
    if (nightlyRate <= 0) {
      return 'Nightly rate must be greater than 0.';
    }
    if (nights <= 0) {
      return 'Nights must be at least 1.';
    }
    final expectedNights = calculateNights(range.start, range.end);
    if (nights != expectedNights) {
      return 'Night count does not match selected dates.';
    }
    final expectedTotal = nights * nightlyRate;
    if (total != expectedTotal) {
      return 'Total does not match nightly rate and nights.';
    }
    return null;
  }

  static String? validateTimeRange({
    required DateTime start,
    required DateTime end,
  }) {
    if (end.isBefore(start)) {
      return 'End time must be after start time.';
    }
    return null;
  }
}

/// Result object returned when reserving or releasing slots.
class BookingSlotUpdate {
  final int available;
  final String? error;

  const BookingSlotUpdate({required this.available, this.error});

  bool get isValid => error == null;
}

/// Slot inventory helpers for reserve/release flows.
class BookingSlots {
  static BookingSlotUpdate reserve({
    required int available,
    required int requested,
  }) {
    if (requested <= 0) {
      return BookingSlotUpdate(
        available: available,
        error: 'Requested slots must be at least 1.',
      );
    }
    if (requested > available) {
      return BookingSlotUpdate(
        available: available,
        error: 'Not enough slots available.',
      );
    }
    return BookingSlotUpdate(available: available - requested);
  }

  static BookingSlotUpdate release({
    required int available,
    required int released,
    required int capacity,
  }) {
    if (released <= 0) {
      return BookingSlotUpdate(
        available: available,
        error: 'Released slots must be at least 1.',
      );
    }
    final next = available + released;
    return BookingSlotUpdate(
      available: next > capacity ? capacity : next,
    );
  }
}

/// In-memory booking list that ensures unique trip keys.
class BookingLedger {
  final List<TripEntry> trips;
  final List<TripEntry> saved;

  const BookingLedger({
    required this.trips,
    required this.saved,
  });

  BookingLedger book(TripEntry trip) {
    // Add to booked list and remove any matching saved item.
    final key = _tripKey(trip.title, trip.location);
    final nextTrips = [...trips];
    final exists = nextTrips.any((t) => _tripKey(t.title, t.location) == key);
    if (!exists) {
      nextTrips.add(trip);
    }
    final nextSaved =
        saved.where((t) => _tripKey(t.title, t.location) != key).toList();
    return BookingLedger(trips: nextTrips, saved: nextSaved);
  }

  BookingLedger cancel({
    required String title,
    required String location,
  }) {
    // Remove a booked trip while leaving saved entries untouched.
    final key = _tripKey(title, location);
    final nextTrips =
        trips.where((t) => _tripKey(t.title, t.location) != key).toList();
    return BookingLedger(trips: nextTrips, saved: [...saved]);
  }

  // Lowercased composite key for title + location.
  String _tripKey(String title, String location) =>
      '${title.toLowerCase()}|${location.toLowerCase()}';
}
