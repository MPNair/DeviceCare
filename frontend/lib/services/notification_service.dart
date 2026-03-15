import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/gadget.dart';
import 'api_service.dart';
import 'settings_provider.dart';
import 'package:provider/provider.dart';
import 'browser_notifications_stub.dart'
    if (dart.library.html) 'browser_notifications_web.dart'
    as browser_notifications;

class NotificationService {
  static const Duration _maxWebTimerChunk = Duration(days: 20);
  static final Map<int, Timer> _webTimers = <int, Timer>{};

  static Future<void> addCustomReminderToCalendar(
    BuildContext context,
    DateTime scheduledDateTime,
    String deviceName, {
    bool repeat = false,
  }) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.addCustomReminder(
      deviceName,
      scheduledDateTime,
      repeat: repeat,
    );
  }

  static Future<void> scheduleDeviceNotification(
    BuildContext context,
    DateTime scheduledDateTime, {
    bool repeat = false,
    required String deviceName,
  }) async {
    await initialize();
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification permission denied.')),
      );
      return;
    }

    final now = DateTime.now();
    final id = _notificationId(
      'custom-device-$deviceName-${scheduledDateTime.millisecondsSinceEpoch}',
    );

    // 1) Always fire an immediate notification so the user sees proof it works
    try {
      await _showNotification(
        id: _notificationId(
          'confirm-$deviceName-${scheduledDateTime.millisecondsSinceEpoch}',
        ),
        title: 'Reminder set \u2705',
        body:
            'You will be reminded about $deviceName at '
            '${scheduledDateTime.hour.toString().padLeft(2, '0')}:'
            '${scheduledDateTime.minute.toString().padLeft(2, '0')} on '
            '${scheduledDateTime.day}/${scheduledDateTime.month}/${scheduledDateTime.year}.',
        payload: 'confirm:$deviceName',
      );
    } catch (e) {
      debugPrint('NotificationService: confirmation show failed: $e');
    }

    // 2) Schedule the actual notification at the target time
    var targetTime = scheduledDateTime;
    if (!targetTime.isAfter(now.add(const Duration(seconds: 5)))) {
      // Time is essentially now or past — fire immediately
      try {
        await _showNotification(
          id: id,
          title: 'Device Reminder',
          body: 'Reminder for $deviceName',
          payload: 'custom:$deviceName',
        );
        debugPrint('NotificationService: time is now — shown immediately');
      } catch (e) {
        debugPrint('NotificationService: immediate show failed: $e');
      }
      return;
    }

    if (kIsWeb) {
      _scheduleWebNotification(
        id: id,
        title: 'Device Reminder',
        body: 'Reminder for $deviceName',
        scheduledDateTime: targetTime,
        repeat: repeat,
      );
      return;
    }

    // Use zonedSchedule across mobile and desktop platforms.
    final tzScheduled = _localToTZ(targetTime);
    debugPrint(
      'NotificationService: scheduling id=$id at=$tzScheduled (${tzScheduled.location.name})',
    );

    bool scheduled = false;

    try {
      await _plugin.zonedSchedule(
        id,
        'Device Reminder',
        'Reminder for $deviceName',
        tzScheduled,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'custom:$deviceName',
        matchDateTimeComponents: repeat ? DateTimeComponents.time : null,
      );
      scheduled = true;
      debugPrint('NotificationService: exact zonedSchedule OK');
    } catch (e) {
      debugPrint('NotificationService: exact failed: $e');
    }

    if (!scheduled) {
      try {
        await _plugin.zonedSchedule(
          id,
          'Device Reminder',
          'Reminder for $deviceName',
          tzScheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'custom:$deviceName',
          matchDateTimeComponents: repeat ? DateTimeComponents.time : null,
        );
        scheduled = true;
        debugPrint('NotificationService: inexact zonedSchedule OK');
      } catch (e) {
        debugPrint('NotificationService: inexact failed: $e');
      }
    }

    if (!scheduled) {
      // zonedSchedule failed — queue via poll timer as fallback
      _desktopSchedule(
        id: id,
        title: 'Device Reminder',
        body: 'Reminder for $deviceName',
        payload: 'custom:$deviceName',
        time: targetTime,
      );
    }
  }

  /// Cancels a previously scheduled custom device notification.
  static Future<void> cancelCustomNotification(
    String deviceName,
    DateTime scheduledDateTime,
  ) async {
    final id = _notificationId(
      'custom-device-$deviceName-${scheduledDateTime.millisecondsSinceEpoch}',
    );
    if (kIsWeb) {
      _cancelWebNotification(id);
      return;
    }

    await initialize();
    _desktopCancel(id);
    if (!_isDesktop) {
      await _plugin.cancel(id);
    }
  }

  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Set<String> _sentImmediateKeys = <String>{};
  static bool _desktopNotifierReady = false;

  /// Shows a notification using platform-appropriate implementation.
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      final ok = await browser_notifications.showNotification(
        title: title,
        body: body,
      );
      if (!ok) {
        debugPrint('NotificationService: browser notification failed id=$id');
      }
      return;
    }

    if (_isDesktop) {
      await _showDesktopNotification(id: id, title: title, body: body);
      return;
    }

    try {
      await _plugin.show(
        id,
        title,
        body,
        _notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService: _plugin.show failed: $e');
    }
  }

  static Future<void> _initDesktopNotifier() async {
    if (!_isDesktop || _desktopNotifierReady) return;
    try {
      await localNotifier.setup(
        appName: 'com.devicecare.frontend',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _desktopNotifierReady = true;
      debugPrint('NotificationService: desktop notifier initialized');
    } catch (e) {
      debugPrint('NotificationService: desktop notifier init failed: $e');
    }
  }

  static Future<void> _showDesktopNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _initDesktopNotifier();
    if (!_desktopNotifierReady) {
      debugPrint('NotificationService: desktop notifier unavailable');
      return;
    }

    try {
      final notification = LocalNotification(
        identifier: 'devicecare_$id',
        title: title,
        body: body,
      );
      await notification.show();
      debugPrint('NotificationService: desktop notification shown id=$id');
    } catch (e) {
      debugPrint('NotificationService: desktop notification failed id=$id: $e');
    }
  }

  /// True when running on a desktop OS (where zonedSchedule is unsupported).
  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  // ── Desktop polling-based scheduler ──
  // A single periodic timer checks system time every second and fires
  // any notifications whose scheduled time has arrived.
  static Timer? _pollTimer;
  static final Map<int, _PendingNotification> _pendingNotifications = {};

  static void _ensurePollTimer() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollPendingNotifications();
    });
    debugPrint('NotificationService: poll timer started');
  }

  static void _pollPendingNotifications() {
    if (_pendingNotifications.isEmpty) return;
    final now = DateTime.now();
    final toFire = <_PendingNotification>[];
    _pendingNotifications.removeWhere((id, pn) {
      if (!pn.scheduledTime.isAfter(now)) {
        toFire.add(pn);
        return true; // remove from map
      }
      return false;
    });
    for (final pn in toFire) {
      debugPrint(
        'NotificationService: poll firing id=${pn.id} "${pn.title}" at $now',
      );
      _showNotification(
        id: pn.id,
        title: pn.title,
        body: pn.body,
        payload: pn.payload,
      );
    }
  }

  /// Queue a notification to be fired by the polling timer at [time].
  static void _desktopSchedule({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime time,
  }) {
    _pendingNotifications[id] = _PendingNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledTime: time,
    );
    _ensurePollTimer();
    debugPrint(
      'NotificationService: desktop queued id=$id at=$time '
      '(in ${time.difference(DateTime.now()).inSeconds}s)',
    );
  }

  static void _desktopCancel(int id) {
    _pendingNotifications.remove(id);
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'devicecare-reminders',
        'DeviceCare Reminders',
        channelDescription: 'Warranty and maintenance reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
      );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  /// Ensures tz.local is set to a valid location. Safe to call multiple times.
  static void _ensureTimezone() {
    tz_data.initializeTimeZones();
    // Always (re-)set tz.local so it survives hot-reload/restart.
    // Android timeZoneName returns abbreviations like "IST" which are not
    // valid IANA identifiers, so we fall back to offset-based matching.
    bool localSet = false;
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
      localSet = true;
    } catch (_) {}
    if (!localSet) {
      final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(loc);
          localSet = true;
          break;
        }
      }
    }
    if (!localSet) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  static Future<void> initialize() async {
    // Always ensure timezone is configured, even across hot-reload
    if (!kIsWeb) {
      _ensureTimezone();
    }

    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    final initResult = await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('NotificationService: tapped payload=${response.payload}');
      },
    );
    debugPrint('NotificationService: init result=$initResult');

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'devicecare-reminders',
            'DeviceCare Reminders',
            description: 'Warranty and maintenance reminder notifications',
            importance: Importance.max,
            playSound: true,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Request exact alarm permission for reliable scheduled notifications
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _initDesktopNotifier();

    _initialized = true;
  }

  static Future<void> syncSchedulesFromApi(BuildContext context) async {
    await initialize();
    _sentImmediateKeys.clear();

    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      return;
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.notificationsEnabled || settings.authToken == null) {
      return;
    }

    // Always re-schedule custom reminders first (these must never be lost)
    await _rescheduleCustomReminders(settings);

    try {
      final gadgets = await ApiService().getGadgets(settings.authToken);
      await _triggerDueNowNotifications(gadgets);
      await scheduleForGadgets(gadgets);
    } catch (_) {
      // API fetch failed — don't wipe existing schedules
    }
  }

  /// Re-schedules all custom reminders from SettingsProvider.
  static Future<void> _rescheduleCustomReminders(
    SettingsProvider settings,
  ) async {
    final now = DateTime.now();
    for (final reminder in settings.customReminders) {
      // For repeating reminders, always re-schedule; for one-time, only if future
      if (reminder.date.isAfter(now) || reminder.repeat) {
        final id = _notificationId(
          'custom-device-${reminder.deviceName}-${reminder.date.millisecondsSinceEpoch}',
        );
        // For one-time reminders, ensure the target is in the future
        var targetDate = reminder.date;
        if (!reminder.repeat &&
            !targetDate.isAfter(now.add(const Duration(seconds: 5)))) {
          targetDate = now.add(const Duration(seconds: 10));
        }
        debugPrint(
          'NotificationService: reschedule id=$id at=$targetDate repeat=${reminder.repeat}',
        );

        if (kIsWeb) {
          _scheduleWebNotification(
            id: id,
            title: 'Device Reminder',
            body: 'Scheduled notification for ${reminder.deviceName}',
            scheduledDateTime: targetDate,
            repeat: reminder.repeat,
          );
          continue;
        }

        final tzScheduled = _localToTZ(targetDate);
        bool ok = false;
        // Try exact first
        if (!ok) {
          try {
            await _plugin.zonedSchedule(
              id,
              'Device Reminder',
              'Scheduled notification for ${reminder.deviceName}',
              tzScheduled,
              _notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'custom:${reminder.deviceName}',
              matchDateTimeComponents: reminder.repeat
                  ? DateTimeComponents.time
                  : null,
            );
            ok = true;
          } catch (e) {
            debugPrint('NotificationService: reschedule exact failed: $e');
          }
        }
        // Fall back to inexact
        if (!ok) {
          try {
            await _plugin.zonedSchedule(
              id,
              'Device Reminder',
              'Scheduled notification for ${reminder.deviceName}',
              tzScheduled,
              _notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'custom:${reminder.deviceName}',
              matchDateTimeComponents: reminder.repeat
                  ? DateTimeComponents.time
                  : null,
            );
            ok = true;
          } catch (e) {
            debugPrint('NotificationService: reschedule inexact failed: $e');
          }
        }
      }
    }
  }

  static Future<bool> sendTestNotificationNow() async {
    await initialize();

    if (kIsWeb) {
      return browser_notifications.showNotification(
        title: 'Test notification',
        body: 'DeviceCare browser notifications are working in Edge/Chrome.',
      );
    }

    final hasPermission = await _ensurePermissions();
    if (!hasPermission) return false;

    final id = _notificationId(
      'manual-test-${DateTime.now().millisecondsSinceEpoch}',
    );
    try {
      await _showNotification(
        id: id,
        title: 'Test notification',
        body: 'DeviceCare notifications are working on this device.',
        payload: 'test:manual',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _ensurePermissions() async {
    if (kIsWeb) {
      return browser_notifications.requestPermission();
    }

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final enabled = await androidImpl.areNotificationsEnabled();
      // null means the check isn't supported on this API level — treat as granted
      if (enabled == false) {
        final requested = await androidImpl.requestNotificationsPermission();
        // null means request not supported — treat as granted
        if (requested == false) return false;
      }
      return true;
    }

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final requested = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (requested == false) return false;
    }

    return true;
  }

  static Future<void> scheduleForGadgets(List<Gadget> gadgets) async {
    await initialize();

    // Cancel only warranty/maintenance notifications (NOT custom reminders).
    // We track them by ID prefix pattern via _notificationId.
    for (final gadget in gadgets) {
      try {
        final w7 = _notificationId('${gadget.id}-warranty-7');
        final w0 = _notificationId('${gadget.id}-warranty-0');
        final m3 = _notificationId('${gadget.id}-maintenance-3');
        final m0 = _notificationId('${gadget.id}-maintenance-0');

        if (kIsWeb) {
          _cancelWebNotification(w7);
          _cancelWebNotification(w0);
          _cancelWebNotification(m3);
          _cancelWebNotification(m0);
        } else {
          _desktopCancel(w7);
          _desktopCancel(w0);
          _desktopCancel(m3);
          _desktopCancel(m0);

          if (!_isDesktop) {
            await _plugin.cancel(w7);
            await _plugin.cancel(w0);
            await _plugin.cancel(m3);
            await _plugin.cancel(m0);
          }
        }
      } catch (e) {
        debugPrint('NotificationService: cancel failed: $e');
      }
    }

    for (final gadget in gadgets) {
      try {
        await _scheduleWarrantyNotifications(gadget);
      } catch (e) {
        debugPrint('NotificationService: warranty schedule error: $e');
      }
      try {
        await _scheduleMaintenanceNotifications(gadget);
      } catch (e) {
        debugPrint('NotificationService: maintenance schedule error: $e');
      }
    }
  }

  static Future<void> _scheduleWarrantyNotifications(Gadget gadget) async {
    final expiry = gadget.warrantyExpiryDate;
    if (expiry == null) return;

    final sevenDaysBefore = expiry.subtract(const Duration(days: 7));

    await _scheduleAt(
      date: sevenDaysBefore,
      id: _notificationId('${gadget.id}-warranty-7'),
      title: 'Warranty expires soon',
      body: '${gadget.name} warranty expires in 7 days.',
      payload: 'warranty:${gadget.id}',
    );

    await _scheduleAt(
      date: expiry,
      id: _notificationId('${gadget.id}-warranty-0'),
      title: 'Warranty expires today',
      body: '${gadget.name} warranty expires today.',
      payload: 'warranty:${gadget.id}',
    );
  }

  static Future<void> _scheduleMaintenanceNotifications(Gadget gadget) async {
    final nextMaintenance = _getNextMaintenanceDate(gadget);
    if (nextMaintenance == null) return;

    final threeDaysBefore = nextMaintenance.subtract(const Duration(days: 3));

    await _scheduleAt(
      date: threeDaysBefore,
      id: _notificationId('${gadget.id}-maintenance-3'),
      title: 'Maintenance reminder',
      body: '${gadget.name} maintenance is due in 3 days.',
      payload: 'maintenance:${gadget.id}',
    );

    await _scheduleAt(
      date: nextMaintenance,
      id: _notificationId('${gadget.id}-maintenance-0'),
      title: 'Maintenance due today',
      body: '${gadget.name} has scheduled maintenance today.',
      payload: 'maintenance:${gadget.id}',
    );
  }

  static DateTime? _getNextMaintenanceDate(Gadget gadget) {
    final customNext = gadget.customFields['nextMaintenanceDate'];
    if (customNext is String && customNext.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(customNext);
      if (parsed != null) return parsed;
    }

    if (gadget.logs.isNotEmpty) {
      final lastService = gadget.logs
          .map((log) => log.serviceDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return lastService.add(const Duration(days: 180));
    }

    return gadget.purchaseDate.add(const Duration(days: 180));
  }

  static Future<void> _scheduleAt({
    required DateTime date,
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = DateTime.now();
    final scheduled = DateTime(date.year, date.month, date.day, 9, 0);

    DateTime effectiveSchedule = scheduled;

    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    if (!scheduled.isAfter(now)) {
      if (isToday) {
        effectiveSchedule = now.add(const Duration(seconds: 45));
      } else {
        return;
      }
    }

    if (kIsWeb) {
      _scheduleWebNotification(
        id: id,
        title: title,
        body: body,
        scheduledDateTime: effectiveSchedule,
      );
      return;
    }

    final tzScheduled = _localToTZ(effectiveSchedule);
    bool ok = false;

    // Try exact
    if (!ok) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        ok = true;
      } catch (e) {
        debugPrint('NotificationService: _scheduleAt exact failed: $e');
      }
    }

    // Fall back to inexact
    if (!ok) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        ok = true;
      } catch (e) {
        debugPrint('NotificationService: _scheduleAt inexact failed: $e');
      }
    }

    // Last resort: poll-based delay
    if (!ok) {
      _desktopSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        time: effectiveSchedule,
      );
    }
  }

  static Future<void> _triggerDueNowNotifications(List<Gadget> gadgets) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final gadget in gadgets) {
      final warranty = gadget.warrantyExpiryDate;
      if (warranty != null) {
        final warrantyDay = DateTime(
          warranty.year,
          warranty.month,
          warranty.day,
        );
        if (warrantyDay == today) {
          await _showImmediate(
            key: '${gadget.id}-warranty-today',
            title: 'Warranty expires today',
            body: '${gadget.name} warranty expires today.',
            payload: 'warranty:${gadget.id}',
          );
        }
      }

      final maintenance = _getNextMaintenanceDate(gadget);
      if (maintenance != null) {
        final maintenanceDay = DateTime(
          maintenance.year,
          maintenance.month,
          maintenance.day,
        );
        if (maintenanceDay == today) {
          await _showImmediate(
            key: '${gadget.id}-maintenance-today',
            title: 'Maintenance due today',
            body: '${gadget.name} has scheduled maintenance today.',
            payload: 'maintenance:${gadget.id}',
          );
        }
      }
    }
  }

  static Future<void> _showImmediate({
    required String key,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (_sentImmediateKeys.contains(key)) return;

    if (kIsWeb) {
      final ok = await browser_notifications.showNotification(
        title: title,
        body: body,
      );
      if (ok) {
        _sentImmediateKeys.add(key);
      }
      return;
    }

    try {
      await _showNotification(
        id: _notificationId('immediate-$key'),
        title: title,
        body: body,
        payload: payload,
      );
      _sentImmediateKeys.add(key);
    } catch (e) {
      debugPrint('NotificationService: immediate show failed, retrying: $e');
      await _showNotification(
        id: _notificationId('retry-immediate-$key'),
        title: title,
        body: body,
        payload: payload,
      );
      _sentImmediateKeys.add(key);
    }
  }

  static int _notificationId(String key) {
    final hash = key.hashCode.abs();
    return hash % 2000000000;
  }

  static void _cancelWebNotification(int id) {
    final timer = _webTimers.remove(id);
    timer?.cancel();
  }

  static void _scheduleWebNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    bool repeat = false,
  }) {
    _cancelWebNotification(id);

    DateTime nextTime = scheduledDateTime;
    if (repeat) {
      final now = DateTime.now();
      nextTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledDateTime.hour,
        scheduledDateTime.minute,
        scheduledDateTime.second,
      );
      if (!nextTime.isAfter(now)) {
        nextTime = nextTime.add(const Duration(days: 1));
      }
    }

    void armTimer() {
      final now = DateTime.now();
      final remaining = nextTime.difference(now);

      if (remaining.inMilliseconds <= 0) {
        browser_notifications
            .showNotification(title: title, body: body)
            .then((ok) {
              debugPrint(
                'NotificationService: web notification id=$id shown=$ok at=${DateTime.now()}',
              );
            })
            .catchError((error) {
              debugPrint(
                'NotificationService: web notification failed id=$id: $error',
              );
            });

        if (repeat) {
          nextTime = nextTime.add(const Duration(days: 1));
          armTimer();
        } else {
          _webTimers.remove(id);
        }
        return;
      }

      final delay = remaining > _maxWebTimerChunk
          ? _maxWebTimerChunk
          : remaining;
      _webTimers[id] = Timer(delay, armTimer);
    }

    armTimer();
    debugPrint(
      'NotificationService: web timer queued id=$id at=$nextTime repeat=$repeat',
    );
  }

  /// Converts a local DateTime to TZDateTime using the device's local timezone.
  static tz.TZDateTime _localToTZ(DateTime local) {
    try {
      _ensureTimezone();
      return tz.TZDateTime.from(local, tz.local);
    } catch (_) {
      // tz.local not set — construct directly from components in UTC
      try {
        final utc = local.toUtc();
        return tz.TZDateTime.utc(
          utc.year,
          utc.month,
          utc.day,
          utc.hour,
          utc.minute,
          utc.second,
        );
      } catch (_) {
        // Absolute last resort — use now + 10s in UTC
        final fallback = DateTime.now().toUtc().add(
          const Duration(seconds: 10),
        );
        return tz.TZDateTime.utc(
          fallback.year,
          fallback.month,
          fallback.day,
          fallback.hour,
          fallback.minute,
          fallback.second,
        );
      }
    }
  }
}

/// Holds a queued notification for the desktop polling timer.
class _PendingNotification {
  final int id;
  final String title;
  final String body;
  final String payload;
  final DateTime scheduledTime;

  const _PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.scheduledTime,
  });
}
