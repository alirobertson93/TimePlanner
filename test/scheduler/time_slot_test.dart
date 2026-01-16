import 'package:test/test.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';

void main() {
  group('TimeSlot', () {
    test('end returns time 15 minutes after start', () {
      final slot = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      expect(slot.end, equals(DateTime(2026, 1, 13, 10, 15)));
    });

    test('next returns the following 15-minute slot', () {
      final slot = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      final next = slot.next;
      expect(next.start, equals(DateTime(2026, 1, 13, 10, 15)));
    });

    test('previous returns the preceding 15-minute slot', () {
      final slot = TimeSlot(DateTime(2026, 1, 13, 10, 15));
      final prev = slot.previous;
      expect(prev.start, equals(DateTime(2026, 1, 13, 10, 0)));
    });

    test('overlaps detects overlapping slots', () {
      final slot1 = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      final slot2 = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      expect(slot1.overlaps(slot2), isTrue);
    });

    test('overlaps returns false for non-overlapping slots', () {
      final slot1 = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      final slot2 = TimeSlot(DateTime(2026, 1, 13, 10, 15));
      expect(slot1.overlaps(slot2), isFalse);
    });

    test('durationToSlots converts duration to slot count', () {
      expect(TimeSlot.durationToSlots(const Duration(minutes: 15)), equals(1));
      expect(TimeSlot.durationToSlots(const Duration(minutes: 30)), equals(2));
      expect(TimeSlot.durationToSlots(const Duration(minutes: 45)), equals(3));
      expect(TimeSlot.durationToSlots(const Duration(minutes: 60)), equals(4));
      expect(TimeSlot.durationToSlots(const Duration(minutes: 20)), equals(2)); // Rounds up
    });

    test('roundDown rounds time to nearest 15-minute mark', () {
      expect(
        TimeSlot.roundDown(DateTime(2026, 1, 13, 10, 7)),
        equals(DateTime(2026, 1, 13, 10, 0)),
      );
      expect(
        TimeSlot.roundDown(DateTime(2026, 1, 13, 10, 17)),
        equals(DateTime(2026, 1, 13, 10, 15)),
      );
      expect(
        TimeSlot.roundDown(DateTime(2026, 1, 13, 10, 32)),
        equals(DateTime(2026, 1, 13, 10, 30)),
      );
    });

    test('roundUp rounds time up to nearest 15-minute mark', () {
      expect(
        TimeSlot.roundUp(DateTime(2026, 1, 13, 10, 0)),
        equals(DateTime(2026, 1, 13, 10, 0)),
      );
      expect(
        TimeSlot.roundUp(DateTime(2026, 1, 13, 10, 1)),
        equals(DateTime(2026, 1, 13, 10, 15)),
      );
      expect(
        TimeSlot.roundUp(DateTime(2026, 1, 13, 10, 17)),
        equals(DateTime(2026, 1, 13, 10, 30)),
      );
      expect(
        TimeSlot.roundUp(DateTime(2026, 1, 13, 10, 50)),
        equals(DateTime(2026, 1, 13, 11, 0)),
      );
    });

    test('equality works correctly', () {
      final slot1 = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      final slot2 = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      final slot3 = TimeSlot(DateTime(2026, 1, 13, 10, 15));

      expect(slot1, equals(slot2));
      expect(slot1, isNot(equals(slot3)));
    });
  });
}
