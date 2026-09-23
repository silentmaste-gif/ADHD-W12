import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationPreferences {
  final bool assessment;
  final bool mood;
  final bool tasks;
  final bool sound;
  final bool vibration;

  const NotificationPreferences({
    this.assessment = true,
    this.mood = true,
    this.tasks = true,
    this.sound = true,
    this.vibration = true,
  });
}

class ReminderNotification {
  final int id;
  final String title;
  final String body;
  final String prompt;
  final int hour;
  final bool Function(NotificationPreferences preferences) enabled;

  const ReminderNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.prompt,
    required this.hour,
    required this.enabled,
  });
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'aidhd_reminders';
  static const _assessmentKey = 'notifications.assessment';
  static const _moodKey = 'notifications.mood';
  static const _tasksKey = 'notifications.tasks';
  static const _soundKey = 'notifications.sound';
  static const _vibrationKey = 'notifications.vibration';
  static void Function(String prompt)? onNotificationTap;

  static const _reminders = [
    ReminderNotification(
      id: 101,
      title: 'Breakfast check-in',
      body: 'Did you eat something this morning?',
      prompt:
          'Did you eat breakfast yet? Help me choose one simple option if I have not.',
      hour: 7,
      enabled: _assessmentEnabled,
    ),
    ReminderNotification(
      id: 102,
      title: 'Water break',
      body: 'A small sip of water can be a good reset.',
      prompt:
          'Remind me gently to drink some water and take one small step now.',
      hour: 9,
      enabled: _taskEnabled,
    ),
    ReminderNotification(
      id: 103,
      title: 'Focus reset',
      body: 'What is the one small thing worth doing next?',
      prompt:
          'Help me choose one small next task and get started without pressure.',
      hour: 11,
      enabled: _taskEnabled,
    ),
    ReminderNotification(
      id: 104,
      title: 'Lunch check-in',
      body: 'Pause for food and a little care before the day runs away.',
      prompt:
          'Did I eat lunch? Ask me gently and help me make a realistic plan.',
      hour: 13,
      enabled: _assessmentEnabled,
    ),
    ReminderNotification(
      id: 105,
      title: 'Movement reminder',
      body: 'A few minutes of movement can help your brain reset.',
      prompt: 'Suggest a gentle movement break that fits how I feel right now.',
      hour: 15,
      enabled: _taskEnabled,
    ),
    ReminderNotification(
      id: 106,
      title: 'Small reset',
      body: 'Check water, food, essentials, and the next task.',
      prompt:
          'Help me check my basic needs and remember anything important without judgment.',
      hour: 17,
      enabled: _taskEnabled,
    ),
    ReminderNotification(
      id: 107,
      title: 'Wind-down reminder',
      body: 'What would make tomorrow a little gentler?',
      prompt:
          'Help me wind down, remember tomorrow\'s essentials, and choose one preparation step.',
      hour: 20,
      enabled: _moodEnabled,
    ),
  ];

  static bool _assessmentEnabled(NotificationPreferences preferences) =>
      preferences.assessment;
  static bool _moodEnabled(NotificationPreferences preferences) =>
      preferences.mood;
  static bool _taskEnabled(NotificationPreferences preferences) =>
      preferences.tasks;

  static Future<String?> initialize() async {
    if (kIsWeb) return null;
    tz.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload ?? '');
      },
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    return launchDetails?.didNotificationLaunchApp == true
        ? launchDetails?.notificationResponse?.payload
        : null;
  }

  static Future<NotificationPreferences> loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return NotificationPreferences(
      assessment: preferences.getBool(_assessmentKey) ?? true,
      mood: preferences.getBool(_moodKey) ?? true,
      tasks: preferences.getBool(_tasksKey) ?? true,
      sound: preferences.getBool(_soundKey) ?? true,
      vibration: preferences.getBool(_vibrationKey) ?? true,
    );
  }

  static Future<void> savePreferences(NotificationPreferences values) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_assessmentKey, values.assessment);
    await preferences.setBool(_moodKey, values.mood);
    await preferences.setBool(_tasksKey, values.tasks);
    await preferences.setBool(_soundKey, values.sound);
    await preferences.setBool(_vibrationKey, values.vibration);
    if (!values.tasks) {
      await _plugin.cancelAll();
    }
    await scheduleDailyReminders(values);
  }

  static Future<void> scheduleDailyReminders([
    NotificationPreferences? values,
  ]) async {
    if (kIsWeb) return;
    final preferences = values ?? await loadPreferences();
    for (final reminder in _reminders) {
      await _plugin.cancel(reminder.id);
    }
    for (final reminder in _reminders) {
      if (reminder.enabled(preferences)) {
        await _scheduleDaily(reminder, preferences);
      }
    }
  }

  static Future<void> _scheduleDaily(ReminderNotification reminder,
      NotificationPreferences preferences) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      reminder.id,
      reminder.title,
      reminder.body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'AiDHD reminders',
          channelDescription:
              'Gentle reminders for focus, routines, and daily care.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: preferences.sound,
          enableVibration: preferences.vibration,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reminder.prompt,
    );
  }

  static Future<void> cancelAll() async {
    if (!kIsWeb) await _plugin.cancelAll();
  }

  static Future<void> scheduleTaskReminder(TaskItem task) async {
    if (kIsWeb || task.completed || task.reminderAt == null) return;
    final preferences = await loadPreferences();
    if (!preferences.tasks) return;
    final reminderAt = task.reminderAt!;
    if (!reminderAt.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _taskNotificationId(task.id),
      'AiDHD task reminder',
      task.title,
      tz.TZDateTime.from(reminderAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'AiDHD reminders',
          channelDescription: 'Gentle reminders for tasks and routines.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: preferences.sound,
          enableVibration: preferences.vibration,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'Help me with this reminder: ${task.title}',
    );
  }

  static Future<void> cancelTaskReminder(TaskItem task) async {
    if (!kIsWeb) await _plugin.cancel(_taskNotificationId(task.id));
  }

  static int _taskNotificationId(String id) {
    var value = 17;
    for (final codeUnit in id.codeUnits) {
      value = (value * 31 + codeUnit) & 0x7fffffff;
    }
    return value;
  }
}
