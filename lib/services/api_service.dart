import 'dart:convert';
import 'dart:io';

import '../models/app_user.dart';
import '../models/goal_item.dart';
import '../models/journal_entry.dart';
import '../models/prayer_response.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({this.baseUrl = 'https://revivespring.onrender.com/api'});

  final String baseUrl;
  String? token;
  AppUser? cachedUser;

  bool get isAuthed => token != null;

  void restoreSession({required String token, required AppUser user}) {
    this.token = token;
    cachedUser = user;
  }

  void restoreToken(String token) {
    this.token = token;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    bool authed = true,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse('$baseUrl$path');
      final req = await client.openUrl(method, uri);
      req.headers.contentType = ContentType.json;
      if (authed && token != null) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) req.write(jsonEncode(body));

      final res = await req.close();
      final text = await utf8.decodeStream(res);
      final data = text.isEmpty ? null : jsonDecode(text);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final message = data is Map
            ? (data['message'] ?? data['error'] ?? 'Request failed.').toString()
            : 'Request failed.';
        throw ApiException(message, statusCode: res.statusCode);
      }
      return data;
    } on SocketException {
      throw ApiException('Network error. Check your connection.');
    } on FormatException {
      throw ApiException('The server returned an unexpected response.');
    } finally {
      client.close(force: true);
    }
  }

  Future<AppUser> login(String email, String password) async {
    final data = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password, 'client': 'mobile'},
      authed: false,
    );
    token = data['token']?.toString();
    cachedUser = AppUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    return cachedUser!;
  }

  Future<AppUser> loginWithGoogle(
    String idToken, {
    String language = 'en',
  }) async {
    final data = await _request(
      'POST',
      '/auth/google',
      body: {'id_token': idToken, 'language': language, 'client': 'mobile'},
      authed: false,
    );
    token = data['token']?.toString();
    cachedUser = AppUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    return cachedUser!;
  }

  Future<void> register(String email, String password, String fullName) {
    return _request(
      'POST',
      '/auth/register',
      body: {'email': email, 'password': password, 'full_name': fullName},
      authed: false,
    ).then((_) {});
  }

  Future<AppUser> verifyOtp(String email, String otp) async {
    final data = await _request(
      'POST',
      '/auth/verify-otp',
      body: {'email': email, 'otp': otp},
      authed: false,
    );
    token = data['token']?.toString();
    cachedUser = AppUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    return cachedUser!;
  }

  Future<void> resendOtp(String email) {
    return _request(
      'POST',
      '/auth/resend-otp',
      body: {'email': email},
      authed: false,
    ).then((_) {});
  }

  Future<void> forgotPassword(String email) {
    return _request(
      'POST',
      '/auth/forgot-password',
      body: {'email': email, 'client': 'mobile'},
      authed: false,
    ).then((_) {});
  }

  Future<void> resetPassword(String email, String otp, String newPassword) {
    return _request(
      'POST',
      '/auth/reset-password',
      body: {'email': email, 'otp': otp, 'new_password': newPassword, 'client': 'mobile'},
      authed: false,
    ).then((_) {});
  }

  Future<List<GoalItem>> getGoals() async {
    final data = await _request('GET', '/goals');
    final list = data is List ? data : (data['goals'] as List? ?? const []);
    return list
        .map(
          (item) => GoalItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AppUser> getCurrentUser() async {
    final data = await _request('GET', '/auth/me');
    cachedUser = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    return cachedUser!;
  }

  Future<void> registerDeviceToken(
    String token, {
    String platform = 'android',
  }) {
    return _request(
      'POST',
      '/notifications/device-token',
      body: {'token': token, 'platform': platform},
    ).then((_) {});
  }

  Future<void> recordVisit() => _request('GET', '/auth/me').then((_) {});

  Future<void> saveOnboarding(Map<String, dynamic> answers) {
    return _request('POST', '/onboarding/save', body: answers).then((_) {});
  }

  Future<Map<String, dynamic>> getDailyVerse() async {
    final data = await _request('GET', '/daily-verse');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<List<Map<String, dynamic>>> getPrayerLibrary() async {
    final data = await _request('GET', '/library');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> completePrayer(
    String mood,
    PrayerResponse response, {
    required int elapsedSeconds,
  }) {
    return _request(
      'POST',
      '/prayers/complete',
      body: {
        'mood': mood,
        'encouragement': response.encouragement,
        'bible_verse': response.verse,
        'bible_reference': response.ref,
        'prayer_text': response.prayer,
        'action_step': response.action,
        'elapsed_seconds': elapsedSeconds,
      },
    ).then((_) {});
  }

  Future<JournalEntry> addJournal(String body) async {
    final data = await _request(
      'POST',
      '/journal',
      body: {
        'title': body.length > 54 ? '${body.substring(0, 54)}...' : body,
        'content': body,
      },
    );
    return JournalEntry.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<GoalItem> completeGoal(
    GoalItem goal, {
    required int elapsedSeconds,
  }) async {
    final data = await _request(
      'POST',
      '/goals/${goal.id}/complete',
      body: {'elapsed_seconds': elapsedSeconds},
    );
    return GoalItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<JournalEntry>> getJournal() async {
    final data = await _request('GET', '/journal');
    final list = data is List
        ? data
        : (data['journal'] as List? ?? data['entries'] as List? ?? const []);
    return list
        .map(
          (item) =>
              JournalEntry.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final data = await _request('GET', '/analytics');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> getWellness() async {
    final data = await _request('GET', '/onboarding/wellness');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> getMonetizationStatus() async {
    final data = await _request('GET', '/monetization/status');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> claimAiUnlock() async {
    final data = await _request('POST', '/monetization/ai/unlock', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<AppUser> syncMobileSubscription(Map<String, dynamic> body) async {
    final data = await _request(
      'POST',
      '/monetization/subscription/mobile-sync',
      body: body,
    );
    final userData = data is Map && data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : Map<String, dynamic>.from(data as Map);
    final fallback = cachedUser;
    if (fallback != null) {
      userData.putIfAbsent('id', () => fallback.id);
      userData.putIfAbsent('email', () => fallback.email);
      userData.putIfAbsent('fullName', () => fallback.fullName);
      userData.putIfAbsent('language', () => fallback.language);
      userData.putIfAbsent('role', () => fallback.role);
      userData.putIfAbsent('photoUrl', () => fallback.photoUrl);
      userData.putIfAbsent('authProvider', () => fallback.authProvider);
      userData.putIfAbsent(
        'hasCompletedOnboarding',
        () => fallback.hasCompletedOnboarding,
      );
      userData.putIfAbsent('timezone', () => fallback.timezone);
      userData.putIfAbsent('reminderHour', () => fallback.reminderHour);
      userData.putIfAbsent('reminderMinute', () => fallback.reminderMinute);
      userData.putIfAbsent(
        'dailyEmailEnabled',
        () => fallback.dailyEmailEnabled,
      );
      userData.putIfAbsent(
        'pushNotificationsEnabled',
        () => fallback.pushNotificationsEnabled,
      );
    }
    cachedUser = AppUser.fromJson(userData);
    return cachedUser!;
  }

  Future<AppUser> updateProfile(Map<String, dynamic> body) async {
    final data = await _request('PATCH', '/auth/me', body: body);
    cachedUser = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    return cachedUser!;
  }

  Future<void> deleteAccount({
    required String reason,
    required String feedback,
  }) {
    return _request(
      'DELETE',
      '/auth/me',
      body: {'reason': reason, 'feedback': feedback},
    ).then((_) {
      token = null;
      cachedUser = null;
    });
  }

  Future<void> submitSupportTicket({
    required String subject,
    required String message,
  }) {
    return _request(
      'POST',
      '/support/tickets',
      body: {'subject': subject, 'message': message},
    ).then((_) {});
  }

  Future<void> addSupportTicketMessage({
    required String ticketId,
    required String message,
  }) {
    return _request(
      'POST',
      '/support/tickets/$ticketId/messages',
      body: {'message': message},
    ).then((_) {});
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final data = await _request('GET', '/notifications');
    final list = data is Map
        ? (data['notifications'] as List? ?? const [])
        : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final data = await _request('GET', '/support/tickets');
    final list = data is Map
        ? (data['tickets'] as List? ?? const [])
        : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  void logout() {
    token = null;
    cachedUser = null;
  }
}
