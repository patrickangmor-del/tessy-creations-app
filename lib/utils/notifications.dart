import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/order.dart';

/// Local (on-device only, no server) reminder notifications ahead of an
/// order's due date. There's no dedicated per-order add/cancel tracking —
/// [syncReminders] just cancels everything and reschedules fresh from the
/// current order list, which is simple, always correct, and cheap enough
/// for how many orders one seamstress has active at a time.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'order_due_reminders';
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    // This app's market (Ghana) is UTC+0 year-round with no daylight
    // saving, so UTC doubles as local time here without needing a device
    // timezone-name lookup (and the extra plugin that would take).
    tz.setLocalLocation(tz.UTC);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(settings: const InitializationSettings(android: androidInit));

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  int _notificationId(String orderId, int variant) => (orderId.hashCode ^ variant) & 0x7fffffff;

  /// Cancels every scheduled reminder and reschedules one for each active
  /// (not yet Delivered) order that has a due date — call this after any
  /// change to the orders list, and once on app startup so reminders are
  /// re-armed even if the device was rebooted since the app last ran.
  Future<void> syncReminders(List<Order> orders) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    for (final order in orders) {
      if (order.status == orderStatuses.last) continue; // Delivered
      final dueDateIso = order.dueDate;
      if (dueDateIso == null) continue;
      final due = DateTime.parse(dueDateIso);

      await _scheduleIfFuture(
        id: _notificationId(order.id, 1),
        when: DateTime(due.year, due.month, due.day - 1, 9),
        title: 'Order due tomorrow',
        body: '${order.dressType} is due tomorrow.',
      );
      await _scheduleIfFuture(
        id: _notificationId(order.id, 2),
        when: DateTime(due.year, due.month, due.day, 9),
        title: 'Order due today',
        body: '${order.dressType} is due today.',
      );
    }
  }

  Future<void> _scheduleIfFuture({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Order due reminders',
          channelDescription: 'Reminders the day before and on the day an order is due',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
