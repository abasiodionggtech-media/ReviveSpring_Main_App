import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_data.dart';
import '../models/app_user.dart';
import '../models/goal_item.dart';
import '../models/journal_entry.dart';
import '../models/prayer_response.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/notification_service.dart';
import '../services/play_billing_service.dart';
import 'app_stage.dart';

class AppController extends ChangeNotifier {
  AppController({ApiService? api}) : api = api ?? ApiService() {
    goals.addAll(seedGoals);
    journal.addAll(seedJournal);
    ready = _restoreSession();
  }

  final ApiService api;
  late final Future<void> ready;
  AppStage stage = AppStage.splash;
  int onboardingIndex = 0;
  String language = 'en';
  bool hasChosenLanguage = false;
  bool signingUp = false;
  bool busy = false;
  String? pendingVerifyEmail;
  AppUser? user;
  final goals = <GoalItem>[];
  final journal = <JournalEntry>[];
  Map<String, dynamic> analytics = {};
  Map<String, dynamic> dailyVerse = {};
  List<Map<String, dynamic>> prayerLibrary = [];
  List<Map<String, dynamic>> alerts = [];
  List<Map<String, dynamic>> supportTickets = [];
  Map<String, dynamic> monetization = {};
  String? pendingSupportTicketId;
  final List<AppStage> _stageHistory = [];

  bool get signedIn => user != null;

  String get _notificationUserKey =>
      (user?.id?.isNotEmpty == true ? user!.id! : user?.email ?? 'guest')
          .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  String get _alertsStorageKey => 'alerts_v1_$_notificationUserKey';

  String get _seenSupportReplyKeysStorageKey =>
      'seen_support_reply_keys_v1_$_notificationUserKey';

  int get unreadAlertCount =>
      alerts.where((item) => item['readAt'] == null).length;
  bool get isPremiumUser => user?.isPremium == true;
  bool get shouldShowAds {
    if (monetization.isEmpty) return false;
    final ads = monetization['ads'];
    final enabled = ads is Map ? ads['enabled'] != false : true;
    final bannerEnabled = ads is Map ? ads['bannerEnabled'] != false : true;
    return signedIn && !isPremiumUser && enabled && bannerEnabled;
  }

  int get aiDailyRemaining {
    final ai = monetization['ai'];
    if (ai is Map && ai['remainingToday'] is num) {
      return (ai['remainingToday'] as num).toInt();
    }
    return isPremiumUser ? 5 : 0;
  }

  String get subscriptionProductId {
    final pricing = monetization['pricing'];
    if (pricing is Map && pricing['googlePlayProductId'] != null) {
      return pricing['googlePlayProductId'].toString();
    }
    return 'revivespring_premium_monthly';
  }

  String get subscriptionPriceLabel {
    final pricing = monetization['pricing'];
    if (pricing is Map) {
      if (language == 'fr' && pricing['labelFr'] != null) {
        return pricing['labelFr'].toString();
      }
      if (pricing['labelEn'] != null) {
        return pricing['labelEn'].toString();
      }
    }
    return language == 'fr' ? '50 nairas / mois' : '50 naira / month';
  }

  String get premiumBannerTitle {
    final ads = monetization['ads'];
    final banner = ads is Map ? ads['banner'] : null;
    if (banner is Map) {
      if (language == 'fr' && banner['titleFr'] != null) {
        return banner['titleFr'].toString();
      }
      if (banner['titleEn'] != null) {
        return banner['titleEn'].toString();
      }
    }
    return 'ReviveSpring Premium';
  }

  String get premiumBannerBody {
    final ads = monetization['ads'];
    final banner = ads is Map ? ads['banner'] : null;
    if (banner is Map) {
      if (language == 'fr' && banner['bodyFr'] != null) {
        return banner['bodyFr'].toString();
      }
      if (banner['bodyEn'] != null) {
        return banner['bodyEn'].toString();
      }
    }
    return language == 'fr'
        ? 'Passez premium sur Android pour retirer les pubs et debloquer les fonctions premium.'
        : 'Upgrade on Android to remove ads and unlock premium features.';
  }

  String get premiumBannerCta {
    final ads = monetization['ads'];
    final banner = ads is Map ? ads['banner'] : null;
    if (banner is Map) {
      if (language == 'fr' && banner['ctaFr'] != null) {
        return banner['ctaFr'].toString();
      }
      if (banner['ctaEn'] != null) {
        return banner['ctaEn'].toString();
      }
    }
    return language == 'fr'
        ? 'Passer premium sur Android'
        : 'Upgrade on Android';
  }

  bool get canHandleSystemBack {
    if (stage == AppStage.splash) return true;
    if (stage == AppStage.onboarding && onboardingIndex > 0) return true;
    return stage != AppStage.app && _stageHistory.isNotEmpty;
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    language = prefs.getString('language') ?? language;
    hasChosenLanguage = prefs.getBool('has_chosen_language') ?? false;

    final savedToken = prefs.getString('auth_token');
    final savedUser = prefs.getString('auth_user');
    if (savedToken == null || savedUser == null) return;

    try {
      final restoredUser = AppUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(savedUser) as Map),
      );
      user = restoredUser;
      api.restoreSession(token: savedToken, user: restoredUser);
      user = await api.getCurrentUser();
      language = user?.language ?? language;
      await _saveSession();
      await refreshMonetizationStatus();
      await _loadAlerts();
      await _processPendingSupportReply();
      await _scheduleHourlyNotificationSync();
      unawaited(_registerDeviceForPush());
    } catch (_) {
      api.logout();
      user = null;
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    }
  }

  Future<void> completeSplash() async {
    await ready;
    _stageHistory.clear();
    stage = signedIn
        ? AppStage.app
        : (hasChosenLanguage ? AppStage.auth : AppStage.language);
    notifyListeners();
    if (signedIn) {
      unawaited(loadRemoteCollections(recordVisit: false));
    }
  }

  Future<void> _saveSession() async {
    final currentUser = user;
    final currentToken = api.token;
    if (currentUser == null || currentToken == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', currentToken);
    await prefs.setString('auth_user', jsonEncode(currentUser.toJson()));
    await prefs.setString('language', language);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  void _setStage(AppStage next, {bool recordHistory = true}) {
    if (stage == next) return;
    if (recordHistory && stage != AppStage.splash) {
      _stageHistory.add(stage);
    }
    stage = next;
  }

  void go(AppStage next) {
    _setStage(next);
    notifyListeners();
  }

  Future<void> chooseLanguage(String value) async {
    language = value;
    hasChosenLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    await prefs.setBool('has_chosen_language', true);
    _setStage(AppStage.auth);
    notifyListeners();
  }

  Future<String?> updateLanguage(String value) async {
    final normalized = value == 'fr' ? 'fr' : 'en';
    final prefs = await SharedPreferences.getInstance();
    language = normalized;
    await prefs.setString('language', normalized);
    if (user == null) {
      notifyListeners();
      return null;
    }
    try {
      user = await api.updateProfile({'language': normalized});
      await _saveSession();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateProfileSettings({
    required bool dailyEmailEnabled,
    required int reminderHour,
    required int reminderMinute,
    String? timezone,
  }) async {
    try {
      user = await api.updateProfile({
        'dailyEmailEnabled': dailyEmailEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'timezone': timezone ?? user?.timezone ?? 'UTC',
      });
      await _saveSession();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  void nextOnboarding() {
    if (onboardingIndex >= onboardingSlides.length - 1) {
      _setStage(signedIn ? AppStage.app : AppStage.auth);
    } else {
      onboardingIndex += 1;
    }
    notifyListeners();
  }

  void previousOnboarding() {
    if (onboardingIndex > 0) onboardingIndex -= 1;
    notifyListeners();
  }

  void setAuthMode(bool value) {
    signingUp = value;
    notifyListeners();
  }

  Future<String?> signIn({
    required String email,
    required String password,
    String? fullName,
  }) async {
    busy = true;
    notifyListeners();
    try {
      if (signingUp) {
        await api.register(email, password, fullName ?? 'Friend');
        pendingVerifyEmail = email;
        _setStage(AppStage.verify);
      } else {
        user = await api.login(email, password);
        await _saveSession();
        _stageHistory.clear();
        _setStage(
          user!.hasCompletedOnboarding ? AppStage.app : AppStage.onboarding,
          recordHistory: false,
        );
        unawaited(loadRemoteCollections());
        unawaited(refreshMonetizationStatus());
        unawaited(_showWelcomeNotification());
        unawaited(_registerDeviceForPush());
        unawaited(_scheduleHourlyNotificationSync());
      }
      return null;
    } on ApiException catch (error) {
      if (error.statusCode == 403) {
        pendingVerifyEmail = email;
        stage = AppStage.verify;
        return null;
      }
      return error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    busy = true;
    notifyListeners();
    try {
      final idToken = await GoogleAuthService.instance.getIdToken();
      user = await api.loginWithGoogle(idToken, language: language);
      await _saveSession();
      _stageHistory.clear();
      _setStage(
        user!.hasCompletedOnboarding ? AppStage.app : AppStage.onboarding,
        recordHistory: false,
      );
      unawaited(loadRemoteCollections());
      unawaited(refreshMonetizationStatus());
      unawaited(_showWelcomeNotification());
      unawaited(_registerDeviceForPush());
      unawaited(_scheduleHourlyNotificationSync());
      return null;
    } on ApiException catch (error) {
      return error.message;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Google sign-in could not finish. Please try again and choose your Google account.';
      }
      return error.description ??
          'Google sign-in is not configured correctly yet.';
    } on GoogleAuthConfigurationException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> verifyOtp(String otp, {bool transition = true}) async {
    final email = pendingVerifyEmail;
    if (email == null) return 'Missing verification email.';
    busy = true;
    notifyListeners();
    try {
      user = await api.verifyOtp(email, otp);
      pendingVerifyEmail = null;
      await _saveSession();
      unawaited(loadRemoteCollections());
      unawaited(refreshMonetizationStatus());
      unawaited(_showWelcomeNotification());
      unawaited(_registerDeviceForPush());
      unawaited(_scheduleHourlyNotificationSync());
      if (transition) completeOtpVerification();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void completeOtpVerification() {
    onboardingIndex = 0;
    _stageHistory.clear();
    _setStage(AppStage.onboarding, recordHistory: false);
    notifyListeners();
  }

  Future<String?> resendOtp() async {
    final email = pendingVerifyEmail;
    if (email == null) return 'Missing verification email.';
    busy = true;
    notifyListeners();
    try {
      await api.resendOtp(email);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await api.forgotPassword(email);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await api.resetPassword(email, otp, newPassword);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> loadRemoteCollections({bool recordVisit = true}) async {
    try {
      if (recordVisit) await api.recordVisit();
      final remoteGoals = await api.getGoals();
      if (remoteGoals.isNotEmpty) {
        goals
          ..clear()
          ..addAll(remoteGoals);
      }
      final remoteJournal = await api.getJournal();
      if (remoteJournal.isNotEmpty) {
        journal
          ..clear()
          ..addAll(remoteJournal);
      }
      analytics = await api.getAnalytics();
      try {
        dailyVerse = await api.getDailyVerse();
      } catch (_) {}
      try {
        prayerLibrary = await api.getPrayerLibrary();
      } catch (_) {}
      try {
        supportTickets = await api.getSupportTickets();
        await _syncCustomerCareAlerts();
      } catch (_) {}
      try {
        monetization = await api.getMonetizationStatus();
      } catch (_) {}
      await _schedulePrayerReminder();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshMonetizationStatus() async {
    try {
      monetization = await api.getMonetizationStatus();
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> unlockAiForFreeUser() async {
    final result = await api.claimAiUnlock();
    monetization = {
      ...monetization,
      'ai': {
        ...(monetization['ai'] is Map
            ? Map<String, dynamic>.from(monetization['ai'])
            : <String, dynamic>{}),
        ...result,
      },
    };
    notifyListeners();
    return result;
  }

  Map<String, dynamic> _buildSubscriptionPayload(
    PlayBillingResult result, {
    bool acknowledged = false,
  }) {
    return {
      'email': user?.email,
      'orderId': result.purchase.purchaseID,
      'productId': result.product.id,
      'purchaseToken':
          result.purchase.verificationData.serverVerificationData.isNotEmpty
          ? result.purchase.verificationData.serverVerificationData
          : result.purchase.verificationData.localVerificationData,
      'purchaseTime': result.purchase.transactionDate != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(result.purchase.transactionDate!) ??
                  DateTime.now().millisecondsSinceEpoch,
            ).toIso8601String()
          : DateTime.now().toIso8601String(),
      'currencyCode': result.product.currencyCode,
      'priceAmountMicros': (result.product.rawPrice * 1000000).round(),
      'packageName': result.purchase.verificationData.source,
      'acknowledged': acknowledged || !result.purchase.pendingCompletePurchase,
    };
  }

  Future<String?> activateGooglePlayBilling() async {
    try {
      final result = await PlayBillingService.instance.purchaseProduct(
        subscriptionProductId,
      );
      await PlayBillingService.instance.completeIfNeeded(result.purchase);
      user = await api.syncMobileSubscription(
        _buildSubscriptionPayload(result, acknowledged: true),
      );
      await _saveSession();
      await refreshMonetizationStatus();
      notifyListeners();
      return null;
    } on PlayBillingException catch (error) {
      return error.message;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> restoreGooglePlayBilling() async {
    try {
      final result = await PlayBillingService.instance.restoreProductPurchase(
        subscriptionProductId,
      );
      await PlayBillingService.instance.completeIfNeeded(result.purchase);
      user = await api.syncMobileSubscription(
        _buildSubscriptionPayload(result, acknowledged: true),
      );
      await _saveSession();
      await refreshMonetizationStatus();
      notifyListeners();
      return null;
    } on PlayBillingException catch (error) {
      return error.message;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertsStorageKey);
    if (raw == null || raw.isEmpty) {
      alerts = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        alerts = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsStorageKey, jsonEncode(alerts));
  }

  Future<void> _syncCustomerCareAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final seenKeys = prefs.getStringList(_seenSupportReplyKeysStorageKey) ?? [];
    final seenSet = seenKeys.toSet();
    var changed = false;

    for (final ticket in supportTickets) {
      final ticketId = (ticket['id'] ?? '').toString();
      final subject = (ticket['subject'] ?? '').toString();
      final messages = ticket['messages'] is List
          ? ticket['messages'] as List
          : const [];
      for (var index = 0; index < messages.length; index++) {
        final rawMessage = messages[index];
        final item = rawMessage is Map
            ? Map<String, dynamic>.from(rawMessage)
            : <String, dynamic>{};
        final fromCare = item['role'] == 'admin';
        if (!fromCare) continue;
        final body = (item['body'] ?? '').toString().trim();
        if (body.isEmpty) continue;
        final key = '$ticketId:$index:$body';
        if (seenSet.contains(key)) continue;
        seenSet.add(key);
        changed = true;
        final alert = {
          'id': key,
          'type': 'customer_care_reply',
          'ticketId': ticketId,
          'title': subject.isEmpty ? 'Customer Care replied' : subject,
          'body': body,
          'createdAt': DateTime.now().toIso8601String(),
          'readAt': null,
        };
        alerts.insert(0, alert);
        unawaited(
          NotificationService.instance.showCustomerCareReply(
            ticketId: ticketId,
            subject: alert['title'].toString(),
            body: body,
          ),
        );
      }
    }

    if (changed) {
      alerts = alerts.take(50).toList();
      await prefs.setStringList(
        _seenSupportReplyKeysStorageKey,
        seenSet.toList(),
      );
      await _saveAlerts();
      notifyListeners();
    }
  }

  Future<void> _schedulePrayerReminder() async {
    final currentUser = user;
    if (currentUser == null) return;
    final verse = verseForToday();
    try {
      await NotificationService.instance.schedulePrayerReminder(
        title: 'Time for your prayer',
        body: '${verse.verse} - ${verse.ref}',
        hour: currentUser.reminderHour,
        minute: currentUser.reminderMinute,
      );
    } catch (_) {}
  }

  Future<void> _showWelcomeNotification() async {
    final currentUser = user;
    if (currentUser == null) return;
    try {
      final allowed = await NotificationService.instance.requestPermission();
      if (!allowed) return;
      await NotificationService.instance.showWelcomeBack(currentUser.fullName);
    } catch (_) {}
  }

  Future<void> _registerDeviceForPush() async {
    try {
      final token = await NotificationService.instance.getFcmToken();
      if (token == null || token.isEmpty) return;
      await api.registerDeviceToken(token);
    } catch (_) {}
  }

  Future<void> _scheduleHourlyNotificationSync() async {
    try {
      await NotificationService.instance.scheduleHourlyNotificationSync();
    } catch (_) {}
  }

  Future<void> _processPendingSupportReply() async {
    try {
      final pending = await NotificationService.instance
          .takePendingSupportReply();
      if (pending == null) return;

      final ticketId = pending['ticketId'] ?? '';
      final message = pending['message'] ?? '';
      if (ticketId.isEmpty || message.isEmpty) return;

      await api.addSupportTicketMessage(ticketId: ticketId, message: message);
      supportTickets = await api.getSupportTickets();
      await _syncCustomerCareAlerts();
      pendingSupportTicketId = ticketId;
      notifyListeners();
    } catch (_) {}
  }

  String? consumePendingSupportTicketId() {
    final ticketId = pendingSupportTicketId;
    pendingSupportTicketId = null;
    return ticketId;
  }

  Future<String?> submitSupportTicket({
    required String subject,
    required String message,
  }) async {
    try {
      await api.submitSupportTicket(subject: subject, message: message);
      supportTickets = await api.getSupportTickets();
      await _syncCustomerCareAlerts();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> addSupportTicketMessage({
    required String ticketId,
    required String message,
  }) async {
    try {
      await api.addSupportTicketMessage(ticketId: ticketId, message: message);
      supportTickets = await api.getSupportTickets();
      await _syncCustomerCareAlerts();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> refreshSupportTickets() async {
    try {
      supportTickets = await api.getSupportTickets();
      await _syncCustomerCareAlerts();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAlertsRead() async {
    final now = DateTime.now().toIso8601String();
    alerts = alerts
        .map((item) => item['readAt'] == null ? {...item, 'readAt': now} : item)
        .toList();
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> markAlertRead(String id) async {
    alerts = alerts
        .map(
          (item) => item['id'] == id && item['readAt'] == null
              ? {...item, 'readAt': DateTime.now().toIso8601String()}
              : item,
        )
        .toList();
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> addJournal(String body) async {
    final entry = await api.addJournal(body);
    journal.insert(0, entry);
    notifyListeners();
  }

  Future<void> completeGoal(GoalItem goal, int elapsedSeconds) async {
    if (goal.done) return;
    final updated = await api.completeGoal(
      goal,
      elapsedSeconds: elapsedSeconds,
    );
    goal.done = updated.done;
    analytics = await api.getAnalytics();
    notifyListeners();
  }

  Future<void> recordPrayer(
    String mood,
    PrayerResponse response,
    int elapsedSeconds,
  ) async {
    await api.completePrayer(mood, response, elapsedSeconds: elapsedSeconds);
    analytics = await api.getAnalytics();
    notifyListeners();
  }

  Future<void> saveOnboarding(Map<String, dynamic> answers) {
    return api.saveOnboarding({
      'language': language,
      'answers': answers,
      if (answers['reminderTime'] != null)
        'reminderTime': answers['reminderTime'],
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logout() async {
    api.logout();
    await _clearSession();
    try {
      await NotificationService.instance.cancelHourlyNotificationSync();
    } catch (_) {}
    // Clear cached purchases to prevent cross-user billing exploit
    PlayBillingService.instance.clearCache();
    user = null;
    pendingVerifyEmail = null;
    alerts = [];
    monetization = {};
    _stageHistory.clear();
    _setStage(AppStage.auth, recordHistory: false);
    notifyListeners();
  }

  Future<String?> deleteAccount({
    required String reason,
    required String feedback,
  }) async {
    try {
      await api.deleteAccount(reason: reason, feedback: feedback);
      await _clearSession();
      try {
        await NotificationService.instance.cancelHourlyNotificationSync();
      } catch (_) {}
      user = null;
      pendingVerifyEmail = null;
      alerts = [];
      monetization = {};
      _stageHistory.clear();
      _setStage(AppStage.auth, recordHistory: false);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  bool handleSystemBack() {
    if (stage == AppStage.splash) return true;
    if (stage == AppStage.onboarding && onboardingIndex > 0) {
      previousOnboarding();
      return true;
    }
    if (stage != AppStage.app && _stageHistory.isNotEmpty) {
      stage = _stageHistory.removeLast();
      notifyListeners();
      return true;
    }
    return false;
  }
}
