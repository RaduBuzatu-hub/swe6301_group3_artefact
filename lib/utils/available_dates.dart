import 'dart:math';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Date utilities for booking flows and availability-based pickers.

/// Stable integer key for a calendar day (YYYYMMDD).
int _dayKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

/// Normalize a DateTime to midnight (date-only).
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Calculate inclusive nights for a date range (minimum 1 night).
int calculateNights(DateTime start, DateTime end) {
  final nights = dateOnly(end).difference(dateOnly(start)).inDays;
  return nights <= 0 ? 1 : nights;
}

/// Build a deterministic list of available dates from a seed.
List<DateTime> buildAvailableDates({
  required String seed,
  int count = 8,
  int rangeDays = 45,
}) {
  final start = dateOnly(DateTime.now()).add(const Duration(days: 1));
  final adjustedRange = max(rangeDays, count + 1);
  final random = Random(seed.hashCode);
  final offsets = <int>{};
  var attempts = 0;
  // Create a few short contiguous blocks to simulate availability windows.
  while (offsets.length < count && attempts < count * 10) {
    final blockStart = random.nextInt(max(2, adjustedRange - 3));
    final blockLength = 2 + random.nextInt(3); // 2-4 day stretches
    for (var i = 0; i < blockLength; i++) {
      offsets.add(blockStart + i);
    }
    attempts++;
  }
  final trimmedOffsets = offsets.take(count);
  final dates = trimmedOffsets
      .map((offset) => dateOnly(start.add(Duration(days: offset))))
      .toList()
    ..sort((a, b) => a.compareTo(b));
  return dates;
}

/// Date picker limited to [availableDates].
Future<DateTime?> showAvailableDatePicker({
  required BuildContext context,
  required List<DateTime> availableDates,
  String helpText = 'Select an available date',
}) {
  if (availableDates.isEmpty) {
    return Future.value(null);
  }
  final normalized = availableDates.map(dateOnly).toList()
    ..sort((a, b) => a.compareTo(b));
  final allowedDays = normalized.map(_dayKey).toSet();
  final firstDate = normalized.first;
  final lastDate = normalized.last;
  return showDatePicker(
    context: context,
    initialDate: firstDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    // Disable days outside the available set.
    selectableDayPredicate: (day) => allowedDays.contains(_dayKey(day)),
  );
}

/// Check if every day in [range] exists in [allowedDays].
bool isRangeAvailable(DateTimeRange range, Set<int> allowedDays) {
  var cursor = dateOnly(range.start);
  final end = dateOnly(range.end);
  while (!cursor.isAfter(end)) {
    if (!allowedDays.contains(_dayKey(cursor))) {
      return false;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return true;
}

/// Date range picker limited to available dates, with validation feedback.
Future<DateTimeRange?> showAvailableDateRangePicker({
  required BuildContext context,
  required List<DateTime> availableDates,
  String helpText = 'Select available dates',
}) async {
  if (availableDates.isEmpty) {
    return null;
  }
  final normalized = availableDates.map(dateOnly).toList()
    ..sort((a, b) => a.compareTo(b));
  final allowedDays = normalized.map(_dayKey).toSet();
  final firstDate = normalized.first;
  final lastDate = normalized.last;
  final selection = await showDateRangePicker(
    context: context,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    // Disable range picks that include unavailable dates.
    selectableDayPredicate: (day, start, end) => allowedDays.contains(_dayKey(day)),
  );
  if (selection == null) return null;
  if (!context.mounted) return null;
  if (!isRangeAvailable(selection, allowedDays)) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Selected range includes unavailable dates.')),
    );
    return null;
  }
  return selection;
}

/// Custom range picker dialog that also shows pricing math.
Future<DateTimeRange?> showPricedDateRangePicker({
  required BuildContext context,
  required List<DateTime> availableDates,
  required int nightlyRate,
  String currencyLabel = 'GBP',
  String helpText = 'Select available dates',
}) async {
  if (availableDates.isEmpty) {
    return null;
  }
  final normalized = availableDates.map(dateOnly).toList()
    ..sort((a, b) => a.compareTo(b));
  final allowedDays = normalized.map(_dayKey).toSet();
  final firstDate = normalized.first;
  final lastDate = normalized.last;
  DateTime? startDate;
  DateTime? endDate;
  DateTime focusedDay = firstDate;
  String? errorText;

  // Use a dialog so we can show a calendar + price summary.
  return showDialog<DateTimeRange>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          int? nights;
          int? total;
          if (startDate != null) {
            final effectiveEnd = endDate ?? startDate!;
            nights = calculateNights(startDate!, effectiveEnd);
            total = nights * nightlyRate;
          }
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(helpText),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DateLabel(label: 'Start', date: startDate),
                    _DateLabel(label: 'End', date: endDate ?? startDate),
                  ],
                ),
                const SizedBox(height: 8),
                if (nights != null && total != null)
                  Text(
                    '$nights ${nights == 1 ? 'night' : 'nights'} - '
                    '$currencyLabel$total',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                else
                  const Text('Select a start date'),
                const SizedBox(height: 4),
                const Text(
                  'Tap a start date, then an end date.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  width: 320,
                  child: TableCalendar(
                    firstDay: firstDate,
                    lastDay: lastDate,
                    focusedDay: focusedDay,
                    rangeStartDay: startDate,
                    rangeEndDay: endDate,
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      rangeHighlightColor:
                          theme.colorScheme.primary.withValues(alpha: 0.14),
                      withinRangeDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      rangeStartDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeStartTextStyle: TextStyle(
                        color: theme.colorScheme.onPrimary,
                      ),
                      rangeEndTextStyle: TextStyle(
                        color: theme.colorScheme.onPrimary,
                      ),
                      withinRangeTextStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      // Mark disabled days with a faint "x".
                      disabledBuilder: (context, day, focusedDay) {
                        final isOutside = day.month != focusedDay.month;
                        final textColor = theme.colorScheme.onSurface
                            .withValues(alpha: isOutside ? 0.25 : 0.45);
                        final xColor = theme.colorScheme.error
                            .withValues(alpha: isOutside ? 0.35 : 0.7);
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Text(
                                'x',
                                style: TextStyle(
                                  color: xColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final isOutside = day.month != focusedDay.month;
                        final textColor = theme.colorScheme.onSurface
                            .withValues(alpha: isOutside ? 0.35 : 0.85);
                        if (isOutside) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 6,
                              right: 6,
                              child: Icon(
                                Icons.check,
                                size: 12,
                                color: Color(0xFF43A047),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // Only enable dates that are available.
                    enabledDayPredicate: (day) => allowedDays.contains(_dayKey(day)),
                    onRangeSelected: (start, end, focused) {
                      setState(() {
                        focusedDay = focused;
                        startDate = start == null ? null : dateOnly(start);
                        endDate = end == null ? null : dateOnly(end);
                        if (startDate != null && endDate != null) {
                          final range = DateTimeRange(start: startDate!, end: endDate!);
                          if (!isRangeAvailable(range, allowedDays)) {
                            errorText = 'Selected range includes unavailable dates.';
                          } else {
                            errorText = null;
                          }
                        } else {
                          errorText = null;
                        }
                      });
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        focusedDay = focused;
                      });
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                // Disable save if dates are invalid or incomplete.
                onPressed: (startDate == null ||
                        (endDate != null &&
                            !isRangeAvailable(
                              DateTimeRange(start: startDate!, end: endDate!),
                              allowedDays,
                            )))
                    ? null
                    : () {
                        final start = startDate!;
                        final end = endDate ?? startDate!;
                        Navigator.of(dialogContext).pop(DateTimeRange(start: start, end: end));
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Small label widget for the start/end date summary.
class _DateLabel extends StatelessWidget {
  final String label;
  final DateTime? date;
  const _DateLabel({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final text = date == null ? '--' : '${date!.day}/${date!.month}/${date!.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
