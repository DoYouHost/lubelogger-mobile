import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Called with a tapped notification's payload (a vehicle id) so the UI isolate
/// can deep-link to that vehicle.
typedef NotificationTapCallback = void Function(String? payload);

/// Thin wrapper over `flutter_local_notifications` for the past-due reminder
/// notifications. Used from both isolates: the UI isolate initializes it and
/// requests permission; the WorkManager background isolate initializes it and
/// posts notifications. Channel name/description are passed in (localized by the
/// caller) so this stays free of any `BuildContext`.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Android channel id for reminder notifications.
  static const remindersChannelId = 'reminders';

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Initialize the plugin and (re)create the reminders channel. Idempotent by
  /// channel id, so calling it from both isolates just keeps the channel's
  /// user-visible [channelName]/[channelDescription] current. Pass [onTap] only
  /// from the UI isolate — the background isolate has no navigator.
  Future<void> init({
    required String channelName,
    required String channelDescription,
    NotificationTapCallback? onTap,
  }) async {
    const android = AndroidInitializationSettings('ic_stat_reminder');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse:
          onTap == null ? null : (response) => onTap(response.payload),
    );
    await _android?.createNotificationChannel(AndroidNotificationChannel(
      remindersChannelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    ));
  }

  /// Request the Android 13+ `POST_NOTIFICATIONS` runtime permission. Returns
  /// whether it's granted (true where no runtime prompt exists, e.g. Android 12
  /// and below). UI-isolate only — a background task cannot prompt.
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  /// Post (or silently update) one past-due reminder notification. The [id]
  /// should be stable per due-cycle so re-posting updates rather than stacks;
  /// combined with `onlyAlertOnce` it won't buzz twice for the same cycle.
  Future<void> showReminder({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channelName,
    required String channelDescription,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        remindersChannelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        onlyAlertOnce: true,
      ),
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Payload of the notification that cold-started the app (a vehicle id), or
  /// null if the app wasn't launched from a notification.
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }
}
