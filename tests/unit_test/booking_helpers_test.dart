/// Unit tests for booking validation, slot math, and ledger updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swe6301_group3_artefact/models/trip_entry.dart';
import 'package:swe6301_group3_artefact/utils/available_dates.dart';
import 'package:swe6301_group3_artefact/utils/booking_helpers.dart';

void main() {
  // Validate booking rules for required fields, ranges, totals, and times.
  group('BookingValidator', () {
    test('requires title and location', () {
      final message = BookingValidator.validateRequiredFields(
        title: '',
        location: 'Cornwall',
      );
      expect(message, 'Title and location are required.');
    });

    test('validates date range ordering and availability', () {
      final start = DateTime(2026, 1, 10);
      final end = DateTime(2026, 1, 12);
      final availableDates = [start, start.add(const Duration(days: 1)), end];
      final allowed = buildAllowedDayKeys(availableDates);
      final range = DateTimeRange(start: start, end: end);

      expect(
        BookingValidator.validateRange(range: range, allowedDays: allowed),
        isNull,
      );

      expect(
        BookingValidator.validateRange(range: null, allowedDays: allowed),
        'Select a date range.',
      );

      final missingMiddle = buildAllowedDayKeys([start, end]);
      expect(
        BookingValidator.validateRange(range: range, allowedDays: missingMiddle),
        'Selected range includes unavailable dates.',
      );
    });

    test('validates totals against nights and nightly rate', () {
      final range = DateTimeRange(
        start: DateTime(2026, 2, 10),
        end: DateTime(2026, 2, 11),
      );
      final nights = calculateNights(range.start, range.end);

      expect(
        BookingValidator.validateTotals(
          range: range,
          nightlyRate: 150,
          nights: nights,
          total: nights * 150,
        ),
        isNull,
      );

      expect(
        BookingValidator.validateTotals(
          range: range,
          nightlyRate: 150,
          nights: nights + 1,
          total: nights * 150,
        ),
        'Night count does not match selected dates.',
      );
    });

    test('validates time range ordering', () {
      final start = DateTime(2026, 3, 1, 10);
      final end = DateTime(2026, 3, 1, 9);
      expect(
        BookingValidator.validateTimeRange(start: start, end: end),
        'End time must be after start time.',
      );
    });
  });

  // Slot reservation and release math.
  group('BookingSlots', () {
    test('decrements slots on reserve and rejects invalid requests', () {
      final reserved = BookingSlots.reserve(available: 5, requested: 2);
      expect(reserved.available, 3);
      expect(reserved.isValid, isTrue);

      final invalid = BookingSlots.reserve(available: 2, requested: 3);
      expect(invalid.available, 2);
      expect(invalid.error, 'Not enough slots available.');
    });

    test('increments slots on release with capacity cap', () {
      final released = BookingSlots.release(
        available: 3,
        released: 4,
        capacity: 5,
      );
      expect(released.available, 5);
      expect(released.isValid, isTrue);
    });
  });

  // Ledger operations for booking, canceling, and deduping trips.
  group('BookingLedger', () {
    TripEntry trip(String title) {
      // Build a minimal TripEntry for ledger tests.
      return TripEntry(
        title: title,
        subtitle: 'Meta',
        location: 'Cornwall',
        price: 'GBP 150',
      );
    }

    test('creates a booking and removes saved duplicate', () {
      final existingSaved = trip('Eco Cabin');
      final ledger = BookingLedger(
        trips: const [],
        saved: [existingSaved],
      );

      final updated = ledger.book(existingSaved);
      expect(updated.trips, hasLength(1));
      expect(updated.saved, isEmpty);
    });

    test('does not duplicate booking entries', () {
      final entry = trip('Eco Cabin');
      final ledger = BookingLedger(
        trips: [entry],
        saved: const [],
      );

      final updated = ledger.book(entry);
      expect(updated.trips, hasLength(1));
    });

    test('cancels an existing booking', () {
      final entry = trip('Eco Cabin');
      final ledger = BookingLedger(
        trips: [entry],
        saved: const [],
      );

      final updated = ledger.cancel(title: 'Eco Cabin', location: 'Cornwall');
      expect(updated.trips, isEmpty);
    });
  });
}
