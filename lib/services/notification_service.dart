import 'dart:ui';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.instance.initialize();
  await NotificationService.instance.handleRemoteMessage(message);
}

@pragma('vm:entry-point')
Future<void> notificationActionBackgroundHandler(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.instance.handleNotificationResponse(response);
}

@pragma('vm:entry-point')
void notificationSyncCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  Workmanager().executeTask((taskName, inputData) async {
    await NotificationService.instance.syncServerNotifications();
    return true;
  });
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _deviceChannel = MethodChannel('revivespring/device');

  bool _initialized = false;
  bool _timeZoneReady = false;
  DateTime? _lastShownAt;

  static const _welcomeChannel = AndroidNotificationChannel(
    'welcome_back',
    'Welcome Back',
    description: 'Welcome-back notifications after sign-in',
    importance: Importance.high,
  );

  static const _supportChannel = AndroidNotificationChannel(
    'customer_care',
    'Customer Care',
    description: 'Replies from the ReviveSpring care team',
    importance: Importance.high,
  );

  static const _prayerChannel = AndroidNotificationChannel(
    'prayer_reminder',
    'Prayer Reminder',
    description: 'Daily reminders for the user prayer time',
    importance: Importance.high,
  );

  static const _prayerReminderId = 2001;
    static const _notificationSyncTaskName = 'revivespring.notification.sync';
    static const _notificationSyncUniqueName =
      'revivespring_notification_sync';
    static const _seenServerNotificationIdsStorageKey =
      'seen_server_notification_ids_v1';
  static const _pendingSupportReplyTicketIdKey =
      'pending_support_reply_ticket_id';
  static const _pendingSupportReplySubjectKey =
      'pending_support_reply_subject';
  static const _pendingSupportReplyMessageKey =
      'pending_support_reply_message';
    bool _backgroundSchedulerReady = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackgroundHandler,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(handleRemoteMessage);

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_welcomeChannel);
    await android?.createNotificationChannel(_supportChannel);
    await android?.createNotificationChannel(_prayerChannel);
    await android?.createNotificationChannel(_securityChannel);
    _initialized = true;
  }

  static const _securityChannel = AndroidNotificationChannel(
    'account_security',
    'Account Security',
    description: 'Account sign-in and security alerts',
    importance: Importance.high,
  );

  Future<void> _configureLocalTimeZone() async {
    if (_timeZoneReady || kIsWeb) return;
    try {
      final timeZoneId = await _deviceChannel.invokeMethod<String>('getTimeZone');
      if (timeZoneId != null && timeZoneId.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(timeZoneId));
      }
    } catch (_) {
      // Fall back to the default timezone location if the platform bridge fails.
    }
    _timeZoneReady = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    await initialize();
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> initializeBackgroundNotificationSync() async {
    if (kIsWeb || _backgroundSchedulerReady) return;
    await initialize();
    await Workmanager().initialize(
      notificationSyncCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    _backgroundSchedulerReady = true;
  }

  Future<void> scheduleHourlyNotificationSync() async {
    if (kIsWeb) return;
    await initializeBackgroundNotificationSync();
    await Workmanager().registerPeriodicTask(
      _notificationSyncUniqueName,
      _notificationSyncTaskName,
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(minutes: 5),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> cancelHourlyNotificationSync() async {
    if (kIsWeb) return;
    await initializeBackgroundNotificationSync();
    await Workmanager().cancelByUniqueName(_notificationSyncUniqueName);
  }

  Future<void> _rememberServerNotificationId(String? notificationId) async {
    if (notificationId == null || notificationId.isEmpty || kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenServerNotificationIdsStorageKey) ?? [];
    if (seen.contains(notificationId)) return;
    seen.insert(0, notificationId);
    await prefs.setStringList(
      _seenServerNotificationIdsStorageKey,
      seen.take(100).toList(),
    );
  }

  Future<bool> _hasSeenServerNotification(String notificationId) async {
    if (notificationId.isEmpty || kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenServerNotificationIdsStorageKey) ?? [];
    return seen.contains(notificationId);
  }

  Future<void> _showSecurityAlert({
    required String notificationId,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _rememberServerNotificationId(notificationId);
    await _notifications.show(
      id: notificationId.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _securityChannel.id,
          _securityChannel.name,
          channelDescription: _securityChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode({'type': 'security', 'notificationId': notificationId}),
    );
  }

  Future<void> showWelcomeBack(String fullName) async {
    if (kIsWeb) return;
    await initialize();

    final now = DateTime.now();
    if (_lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastShownAt = now;

    final firstName = fullName.trim().isEmpty
        ? 'Friend'
        : fullName.trim().split(RegExp(r'\s+')).first;

    await _notifications.show(
      id: 1001,
      title: 'Welcome back',
      body: 'Good to see you, $firstName.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _welcomeChannel.id,
          _welcomeChannel.name,
          channelDescription: _welcomeChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showCustomerCareReply({
    required String ticketId,
    required String subject,
    required String body,
    String? notificationId,
  }) async {
    if (kIsWeb) return;
    await initialize();
    if (notificationId != null && notificationId.isNotEmpty) {
      await _rememberServerNotificationId(notificationId);
    }
    final payload = jsonEncode({
      'type': 'customer_care_reply',
      'ticketId': ticketId,
      'subject': subject,
      if (notificationId != null && notificationId.isNotEmpty)
        'notificationId': notificationId,
    });
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      title: subject.isEmpty ? 'Customer Care replied' : subject,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _supportChannel.id,
          _supportChannel.name,
          channelDescription: _supportChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'reply',
              'Reply',
              inputs: <AndroidNotificationActionInput>[
                const AndroidNotificationActionInput(label: 'Type your reply'),
              ],
              semanticAction: SemanticAction.reply,
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'open',
              'Open chat',
              showsUserInterface: true,
              cancelNotification: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> handleRemoteMessage(RemoteMessage message) async {
    final data = message.data;
    final notificationId = data['notificationId']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    if (notificationId.isNotEmpty) {
      await _rememberServerNotificationId(notificationId);
    }

    if (type == 'customer_care_reply' || type == 'support_reply') {
      await showCustomerCareReply(
        ticketId: data['ticketId']?.toString() ?? '',
        subject: data['subject']?.toString() ?? 'Customer Care replied',
        body: data['body']?.toString() ?? '',
        notificationId: notificationId.isNotEmpty ? notificationId : null,
      );
      return;
    }

    if (type == 'security') {
      await _showSecurityAlert(
        notificationId: notificationId.isNotEmpty
            ? notificationId
            : DateTime.now().microsecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? 'Security alert',
        body: data['body']?.toString() ?? '',
      );
      return;
    }

    final notification = message.notification;
    final title = notification?.title ?? data['title']?.toString() ?? 'ReviveSpring';
    final body = notification?.body ?? data['body']?.toString() ?? '';
    if (title.isNotEmpty || body.isNotEmpty) {
      await _showSecurityAlert(
        notificationId: notificationId.isNotEmpty
            ? notificationId
            : DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        body: body,
      );
    }
  }

  Future<void> syncServerNotifications() async {
    if (kIsWeb) return;
    await initialize();

    final deadline = DateTime.now().add(const Duration(seconds: 20));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;

    final api = ApiService();
    api.restoreToken(token);

    try {
      final notifications = await api.getNotifications();
      for (final item in notifications) {
        if (DateTime.now().isAfter(deadline)) break;

        final notificationId = (item['id'] ?? '').toString();
        if (notificationId.isEmpty) continue;
        if (await _hasSeenServerNotification(notificationId)) continue;

        final type = (item['type'] ?? '').toString();
        final title = (item['title'] ?? '').toString();
        final body = (item['body'] ?? '').toString();
        final metadata = item['metadata'] is Map
            ? Map<String, dynamic>.from(item['metadata'] as Map)
            : <String, dynamic>{};

        if (type == 'support_reply') {
          await showCustomerCareReply(
            ticketId: metadata['ticketId']?.toString() ?? '',
            subject: title.isEmpty ? 'Customer care replied' : title,
            body: body,
            notificationId: notificationId,
          );
        } else {
          await _showSecurityAlert(
            notificationId: notificationId,
            title: title.isEmpty ? 'ReviveSpring' : title,
            body: body,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (data == null) return;
    if (data['type']?.toString() != 'customer_care_reply') return;
    if (response.actionId != 'reply') return;

    final replyText = response.input?.trim();
    final ticketId = data['ticketId']?.toString() ?? '';
    if (replyText == null || replyText.isEmpty || ticketId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingSupportReplyTicketIdKey, ticketId);
      await prefs.setString(
        _pendingSupportReplySubjectKey,
        data['subject']?.toString() ?? '',
      );
      await prefs.setString(_pendingSupportReplyMessageKey, replyText);
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;
      final api = ApiService();
      api.restoreToken(token);
      await api.addSupportTicketMessage(ticketId: ticketId, message: replyText);
      await clearPendingSupportReply();
    } catch (_) {}
  }

  Future<Map<String, String>?> takePendingSupportReply() async {
    final prefs = await SharedPreferences.getInstance();
    final ticketId = prefs.getString(_pendingSupportReplyTicketIdKey) ?? '';
    final subject = prefs.getString(_pendingSupportReplySubjectKey) ?? '';
    final message = prefs.getString(_pendingSupportReplyMessageKey) ?? '';
    if (ticketId.isEmpty || message.isEmpty) return null;
    await clearPendingSupportReply();
    return {
      'ticketId': ticketId,
      'subject': subject,
      'message': message,
    };
  }

  Future<void> clearPendingSupportReply() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSupportReplyTicketIdKey);
    await prefs.remove(_pendingSupportReplySubjectKey);
    await prefs.remove(_pendingSupportReplyMessageKey);
  }

  Future<void> schedulePrayerReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.cancel(id: _prayerReminderId);
    await _notifications.zonedSchedule(
      id: _prayerReminderId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannel.id,
          _prayerChannel.name,
          channelDescription: _prayerChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelPrayerReminder() async {
    if (kIsWeb) return;
    await initialize();
    await _notifications.cancel(id: _prayerReminderId);
  }
}
