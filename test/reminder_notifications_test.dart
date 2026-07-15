import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/models/reminder_record.dart';
import 'package:lubelogger_mobile/core/notifications/reminder_notifications.dart';

ReminderRecord reminder({
  required int id,
  ReminderUrgency urgency = ReminderUrgency.pastDue,
  ReminderMetric metric = ReminderMetric.date,
  DateTime? dueDate,
  double? dueOdometer,
  String description = 'Oil change',
}) =>
    ReminderRecord(
      id: id,
      description: description,
      urgency: urgency,
      metric: metric,
      dueDate: dueDate,
      dueOdometer: dueOdometer,
      notes: '',
      tags: '',
    );

ReminderAlert alert(int reminderId, {int vehicleId = 1, DateTime? dueDate}) =>
    reminderAlertFor(
      vehicleId,
      'Car',
      reminder(id: reminderId, dueDate: dueDate),
    )!;

void main() {
  group('reminderAlertFor', () {
    test('returns an alert only for past-due reminders', () {
      expect(reminderAlertFor(1, 'Car', reminder(id: 1)), isNotNull);
      for (final u in [
        ReminderUrgency.notUrgent,
        ReminderUrgency.urgent,
        ReminderUrgency.veryUrgent,
        ReminderUrgency.unknown,
      ]) {
        expect(reminderAlertFor(1, 'Car', reminder(id: 1, urgency: u)), isNull,
            reason: 'urgency $u must not alert');
      }
    });

    test('carries vehicle + reminder identity into the key', () {
      final a = reminderAlertFor(
        7,
        'Truck',
        reminder(id: 42, dueDate: DateTime(2026, 1, 2)),
      )!;
      expect(a.vehicleId, 7);
      expect(a.reminderId, 42);
      expect(a.dueKey, contains('v7'));
      expect(a.dueKey, contains('r42'));
    });
  });

  group('reminderDueKey', () {
    test('same reminder + same due target → same key', () {
      final k1 = reminderDueKey(
          vehicleId: 1, reminderId: 5, dueDate: DateTime(2026, 5, 1));
      final k2 = reminderDueKey(
          vehicleId: 1, reminderId: 5, dueDate: DateTime(2026, 5, 1));
      expect(k1, k2);
    });

    test('recurrence (rolled-forward due target) yields a new key', () {
      final before = reminderDueKey(
          vehicleId: 1, reminderId: 5, dueDate: DateTime(2026, 5, 1));
      final after = reminderDueKey(
          vehicleId: 1, reminderId: 5, dueDate: DateTime(2026, 8, 1));
      expect(before, isNot(after));
    });

    test('odometer targets differentiate the key', () {
      final a = reminderDueKey(vehicleId: 1, reminderId: 5, dueOdometer: 10000);
      final b = reminderDueKey(vehicleId: 1, reminderId: 5, dueOdometer: 20000);
      expect(a, isNot(b));
    });
  });

  group('planReminderNotifications', () {
    test('first sighting of a past-due reminder is notified', () {
      final plan = planReminderNotifications([alert(1), alert(2)], {});
      expect(plan.toNotify.map((a) => a.reminderId), [1, 2]);
      expect(plan.nextNotified, {alert(1).dueKey, alert(2).dueKey});
    });

    test('already-notified reminder is not notified again', () {
      final a = alert(1);
      final plan = planReminderNotifications([a], {a.dueKey});
      expect(plan.toNotify, isEmpty);
      // Still past due → stays in the persisted set.
      expect(plan.nextNotified, {a.dueKey});
    });

    test('resolved reminder drops out of the persisted set', () {
      final a = alert(1);
      // Was notified before, now no longer past due (absent from the list).
      final plan = planReminderNotifications([], {a.dueKey});
      expect(plan.toNotify, isEmpty);
      expect(plan.nextNotified, isEmpty);
    });

    test('a reminder that returns after resolving notifies again', () {
      final a = alert(1);
      // Cycle 1: notify, persist {a}.
      var plan = planReminderNotifications([a], {});
      expect(plan.toNotify, hasLength(1));
      // Resolved: persist {}.
      plan = planReminderNotifications([], plan.nextNotified);
      expect(plan.nextNotified, isEmpty);
      // Returns (same key): notifies again.
      plan = planReminderNotifications([a], plan.nextNotified);
      expect(plan.toNotify, hasLength(1));
    });

    test('recurrence to a new due date notifies again even if still past due', () {
      final first = alert(1, dueDate: DateTime(2026, 1, 1));
      final rolled = alert(1, dueDate: DateTime(2026, 6, 1));
      // Notified on the first cycle.
      var plan = planReminderNotifications([first], {});
      expect(plan.toNotify, hasLength(1));
      // Next check: same id but rolled-forward (still past due) → new key → notify.
      plan = planReminderNotifications([rolled], plan.nextNotified);
      expect(plan.toNotify.single.dueKey, rolled.dueKey);
    });

    test('duplicate keys within one run are collapsed', () {
      final a = alert(1);
      final plan = planReminderNotifications([a, a], {});
      expect(plan.toNotify, hasLength(1));
    });

    test('mixed: one new, one already known', () {
      final a1 = alert(1);
      final a2 = alert(2);
      final plan = planReminderNotifications([a1, a2], {a1.dueKey});
      expect(plan.toNotify.single.reminderId, 2);
      expect(plan.nextNotified, {a1.dueKey, a2.dueKey});
    });
  });
}
