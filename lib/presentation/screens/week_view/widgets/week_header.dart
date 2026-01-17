import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Header widget showing the days of the week
class WeekHeader extends StatelessWidget {
  const WeekHeader({
    super.key,
    required this.weekStart,
    required this.selectedDate,
    required this.onDayTap,
  });

  final DateTime weekStart;
  final DateTime selectedDate;
  final void Function(DateTime) onDayTap;

  static const double headerHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isToday = _isSameDay(date, now);
          final isSelected = _isSameDay(date, selectedDate);
          final dayName = DateFormat.E().format(date);
          final dayNumber = date.day.toString();

          return Expanded(
            child: GestureDetector(
              onTap: () => onDayTap(date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? theme.colorScheme.primary : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          dayNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? theme.colorScheme.onPrimary
                                : isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
