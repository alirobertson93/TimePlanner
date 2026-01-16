import 'package:flutter/material.dart';

/// Widget displaying an hour marker on the timeline
class TimeMarker extends StatelessWidget {
  const TimeMarker({
    super.key,
    required this.hour,
    required this.height,
  });

  final int hour;
  final double height;

  @override
  Widget build(BuildContext context) {
    final timeText = _formatHour(hour);

    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}
