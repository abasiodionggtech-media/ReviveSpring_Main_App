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

  // ── Mood Check-In (Daily) ────────────────────────────────────
  Future<Map<String, dynamic>> getMoodCheckInToday() async {
    final data = await _request('GET', '/mood-checkin/today');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<void> logMoodCheckIn(String mood, {String? note}) {
    return _request(
      'POST',
      '/mood-checkin',
      body: {'mood': mood, if (note != null && note.isNotEmpty) 'note': note},
    ).then((_) {});
  }

  Future<List<Map<String, dynamic>>> getMoodHistory({int days = 30}) async {
    final data = await _request('GET', '/mood-checkin/history?days=$days');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // ── Daily Manna (Daily Reward) ───────────────────────────────
  Future<Map<String, dynamic>> getDailyMannaStatus() async {
    final data = await _request('GET', '/daily-manna/status');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> claimDailyManna() async {
    final data = await _request('POST', '/daily-manna/claim', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Verse of the Moment ──────────────────────────────────────
  Future<Map<String, dynamic>> getRandomVerse() async {
    final data = await _request('GET', '/daily-verse/random');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Prophetic Declarations ───────────────────────────────────
  Future<Map<String, dynamic>> getTodaysDeclaration() async {
    final data = await _request('GET', '/declarations/today');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> confirmDeclaration() async {
    final data = await _request('POST', '/declarations/confirm', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Answered Prayer Wall ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPrayers({bool answeredOnly = false}) async {
    final data = await _request(
      'GET',
      answeredOnly ? '/prayers?answered=true' : '/prayers',
    );
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> markPrayerAnswered(
    String prayerId, {
    required bool isAnswered,
    String? testimony,
  }) async {
    final data = await _request(
      'PATCH',
      '/prayers/$prayerId/answered',
      body: {
        'is_answered': isAnswered,
        if (testimony != null) 'testimony': testimony,
      },
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Topical Scripture Search ─────────────────────────────────
  Future<Map<String, dynamic>> getScriptureSearchStatus() async {
    final data = await _request('GET', '/scripture-search/status');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> searchScripture(String topic, {String? language}) async {
    final data = await _request(
      'POST',
      '/scripture-search',
      body: {'topic': topic, if (language != null) 'language': language},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── AI Prayer Writer (Premium) ────────────────────────────────
  Future<Map<String, dynamic>> writeAiPrayer(String description, {String? language}) async {
    final data = await _request(
      'POST',
      '/ai-prayer-writer',
      body: {'description': description, if (language != null) 'language': language},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── 30-Day Prayer Challenges ─────────────────────────────────
  Future<List<Map<String, dynamic>>> getChallenges() async {
    final data = await _request('GET', '/challenges');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> joinChallenge(String id) async {
    final data = await _request('POST', '/challenges/$id/join', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> checkInChallenge(String id) async {
    final data = await _request('POST', '/challenges/$id/check-in', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Fasting Tracker ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFasts() async {
    final data = await _request('GET', '/fasts');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>?> getActiveFast() async {
    final data = await _request('GET', '/fasts/active');
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<Map<String, dynamic>> startFast(String fastType, {int goalHours = 24, String? notes}) async {
    final data = await _request(
      'POST',
      '/fasts/start',
      body: {'fast_type': fastType, 'goal_hours': goalHours, if (notes != null) 'notes': notes},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> endFast(String id, {required bool completed}) async {
    final data = await _request(
      'POST',
      '/fasts/$id/end',
      body: {'status': completed ? 'completed' : 'broken'},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Bible Reading Plan ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getReadingPlans() async {
    final data = await _request('GET', '/reading-plans');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> startReadingPlan(String id) async {
    final data = await _request('POST', '/reading-plans/$id/start', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> checkOffReadingPlanDay(String id) async {
    final data = await _request('POST', '/reading-plans/$id/check-off', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Faith Milestones & Badges ────────────────────────────────
  Future<Map<String, dynamic>> checkMilestones() async {
    final data = await _request('POST', '/milestones/check', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Scripture Memory Cards ───────────────────────────────────
  Future<List<Map<String, dynamic>>> getMemoryCards() async {
    final data = await _request('GET', '/memory-cards');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> addMemoryCard(String id) async {
    final data = await _request('POST', '/memory-cards/$id/add', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> reviewMemoryCard(String id) async {
    final data = await _request('POST', '/memory-cards/$id/review', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> quizMemoryCard(String id, {required bool passed}) async {
    final data = await _request('POST', '/memory-cards/$id/quiz', body: {'passed': passed});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── AI Spiritual Companion (Premium) ─────────────────────────
  Future<Map<String, dynamic>> getCompanionHistory() async {
    final data = await _request('GET', '/ai-companion/history');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> sendCompanionMessage(String message, {String? language}) async {
    final data = await _request(
      'POST',
      '/ai-companion/chat',
      body: {'message': message, if (language != null) 'language': language},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── AI Sermon Summarizer (Premium) ───────────────────────────
  Future<Map<String, dynamic>> summarizeSermon(String text, {String? language}) async {
    final data = await _request(
      'POST',
      '/ai-sermon-summarizer',
      body: {'text': text, if (language != null) 'language': language},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── AI Dream/Vision Journal (Premium) ─────────────────────────
  Future<List<Map<String, dynamic>>> getDreamJournal() async {
    final data = await _request('GET', '/dream-journal');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> submitDreamEntry(String description, {String? title, String? language}) async {
    final data = await _request(
      'POST',
      '/dream-journal',
      body: {
        'description': description,
        if (title != null) 'title': title,
        if (language != null) 'language': language,
      },
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Spiritual Growth Score ───────────────────────────────────
  Future<Map<String, dynamic>> getGrowthScore() async {
    final data = await _request('GET', '/growth-score');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Worship Mode (Premium) ────────────────────────────────────
  Future<List<Map<String, dynamic>>> getWorshipTracks() async {
    final data = await _request('GET', '/worship-tracks');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // ── Weekly Spiritual Review ───────────────────────────────────
  Future<Map<String, dynamic>> getWeeklyReview({String? language}) async {
    final data = await _request(
      'GET',
      language != null ? '/weekly-review?language=$language' : '/weekly-review',
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<List<Map<String, dynamic>>> getWeeklyReviewHistory() async {
    final data = await _request('GET', '/weekly-review/history');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> saveWeeklyReflection(String reflection, {String? language}) async {
    final data = await _request(
      'POST',
      '/weekly-review/reflection',
      body: {'reflection': reflection, if (language != null) 'language': language},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Grief & Crisis Support / Mental Health Content ───────────
  Future<Map<String, dynamic>> getCrisisSupport({String? language}) async {
    final data = await _request(
      'GET',
      language != null ? '/mental-health-content/crisis-support?language=$language' : '/mental-health-content/crisis-support',
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Prayer Chain ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPrayerChain() async {
    final data = await _request('GET', '/prayer-chain');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> postPrayerRequest(String text, {String? category, bool isAnonymous = false}) async {
    final data = await _request(
      'POST',
      '/prayer-chain',
      body: {'text': text, if (category != null) 'category': category, 'is_anonymous': isAnonymous},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> prayForRequest(String id) async {
    final data = await _request('POST', '/prayer-chain/$id/pray', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Testimony Feed ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTestimonies() async {
    final data = await _request('GET', '/testimonies');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> postTestimony(String title, String content, {bool isAnonymous = false}) async {
    final data = await _request(
      'POST',
      '/testimonies',
      body: {'title': title, 'content': content, 'is_anonymous': isAnonymous},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> reactToTestimony(String id) async {
    final data = await _request('POST', '/testimonies/$id/react', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Accountability Partner ────────────────────────────────────
  Future<Map<String, dynamic>?> getAccountabilityPartner() async {
    final data = await _request('GET', '/accountability/partner');
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<Map<String, dynamic>> createAccountabilityInvite() async {
    final data = await _request('POST', '/accountability/invite', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<void> acceptAccountabilityInvite(String code) {
    return _request('POST', '/accountability/accept', body: {'invite_code': code}).then((_) {});
  }

  Future<void> sendAccountabilityNudge({String? message}) {
    return _request('POST', '/accountability/nudge', body: {if (message != null) 'message': message}).then((_) {});
  }

  // ── Prayer Groups (Premium) ───────────────────────────────────
  Future<List<Map<String, dynamic>>> getPrayerGroups() async {
    final data = await _request('GET', '/prayer-groups');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> createPrayerGroup(String name, {String? description}) async {
    final data = await _request(
      'POST',
      '/prayer-groups',
      body: {'name': name, if (description != null) 'description': description},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> joinPrayerGroup(String id) async {
    final data = await _request('POST', '/prayer-groups/$id/join', body: {});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> getPrayerGroupDetail(String id) async {
    final data = await _request('GET', '/prayer-groups/$id');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> postGroupPrayerRequest(String groupId, String text, {bool isAnonymous = false}) async {
    final data = await _request(
      'POST',
      '/prayer-groups/$groupId/requests',
      body: {'text': text, 'is_anonymous': isAnonymous},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Spiritual Mentorship Matching (Premium) ───────────────────
  Future<Map<String, dynamic>> becomeMentor({String? bio, List<String>? focusAreas}) async {
    final data = await _request(
      'POST',
      '/mentorship/profile',
      body: {if (bio != null) 'bio': bio, if (focusAreas != null) 'focus_areas': focusAreas},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<List<Map<String, dynamic>>> getMentors() async {
    final data = await _request('GET', '/mentorship/mentors');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> requestMentor(String mentorUserId) async {
    final data = await _request('POST', '/mentorship/request', body: {'mentor_user_id': mentorUserId});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<List<Map<String, dynamic>>> getMyMentorshipMatches() async {
    final data = await _request('GET', '/mentorship/my-matches');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> respondToMentorshipMatch(String matchId, {required bool accept}) async {
    final data = await _request('POST', '/mentorship/$matchId/respond', body: {'accept': accept});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> mentorshipCheckIn(String matchId, String note) async {
    final data = await _request('POST', '/mentorship/$matchId/check-in', body: {'note': note});
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Seasonal Events ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSeasonalEvents() async {
    final data = await _request('GET', '/seasonal-events');
    final list = data is List ? data : const [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
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
