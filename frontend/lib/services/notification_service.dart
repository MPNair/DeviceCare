import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/gadget.dart';
import 'api_service.dart';
import 'settings_provider.dart';
import 'package:provider/provider.dart';
import 'browser_notifications_stub.dart'
    if (dart.library.html) 'browser_notifications_web.dart'
    as browser_notifications;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Set<String> _sentImmediateKeys = <String>{};

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

  static Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

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

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

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
      if (!kIsWeb) {
        await _plugin.cancelAll();
      }
      return;
    }

    final gadgets = await ApiService().getGadgets(settings.authToken);
    await _triggerDueNowNotifications(gadgets);

    try {
      await scheduleForGadgets(gadgets);
    } catch (_) {}
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
      await _plugin.show(
        id,
        'Test notification',
        'DeviceCare notifications are working on this device.',
        _notificationDetails,
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

    bool granted = true;

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final enabled = await androidImpl.areNotificationsEnabled();
      if (enabled != true) {
        final requested = await androidImpl.requestNotificationsPermission();
        granted = granted && (requested ?? false);
      }
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
      granted = granted && (requested ?? false);
    }

    return granted;
  }

  static Future<void> scheduleForGadgets(List<Gadget> gadgets) async {
    await initialize();

    if (kIsWeb) {
      return;
    }

    await _plugin.cancelAll();

    for (final gadget in gadgets) {
      try {
        await _scheduleWarrantyNotifications(gadget);
      } catch (_) {}
      try {
        await _scheduleMaintenanceNotifications(gadget);
      } catch (_) {}
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

    final tzScheduled = tz.TZDateTime.from(effectiveSchedule, tz.local);

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
    } catch (_) {
      final isSameDay =
          now.year == effectiveSchedule.year &&
          now.month == effectiveSchedule.month &&
          now.day == effectiveSchedule.day;
      if (isSameDay) {
        await _plugin.show(
          id,
          title,
          body,
          _notificationDetails,
          payload: payload,
        );
      }
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
      await _plugin.show(
        _notificationId('immediate-$key'),
        title,
        body,
        _notificationDetails,
        payload: payload,
      );
      _sentImmediateKeys.add(key);
    } catch (_) {
      await _plugin.show(
        _notificationId('retry-immediate-$key'),
        title,
        body,
        _notificationDetails,
        payload: payload,
      );
      _sentImmediateKeys.add(key);
    }
  }

  static int _notificationId(String key) {
    final hash = key.hashCode.abs();
    return hash % 2000000000;
  }
}
