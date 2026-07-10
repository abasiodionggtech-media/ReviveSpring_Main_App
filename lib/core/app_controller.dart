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
import 'app_typography.dart';

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
  String fontFamily = 'Inter';
  double fontScale = 1.0;
  bool hasChosenLanguage = false;
  bool signingUp = false;
  bool busy = false;
  String? pendingVerifyEmail;
  AppUser? user;
  final goals = <GoalItem>[];
  final journal = <JournalEntry>[];
  Map<String, dynamic> analytics = {};
  Map<String, dynamic> moodCheckInToday = {};
  Map<String, dynamic> dailyManna = {};
  Map<String, dynamic> todaysDeclaration = {};
  List<Map<String, dynamic>> prayers = [];
  Map<String, dynamic> growthScore = {};
  List<Map<String, dynamic>> seasonalEvents = [];
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

  List<Map<String, dynamic>> get subscriptionPlans {
    final plans = monetization['plans'];
    if (plans is List) {
      return plans.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return const [];
  }

  Map<String, dynamic>? planFor(String tier) {
    for (final plan in subscriptionPlans) {
      if (plan['tier'] == tier) return plan;
    }
    return null;
  }

  String productIdFor(String tier) {
    final plan = planFor(tier);
    if (plan != null && plan['googlePlayProductId'] != null) {
      return plan['googlePlayProductId'].toString();
    }
    return tier == 'standard'
        ? 'revivespring_standard_3mo'
        : 'revivespring_premium_3mo';
  }

  /// A short "From $X / month" label for the dismissible home banner —
  /// pulled from the cheaper (standard) plan.
  String get subscriptionPriceLabel {
    final standard = planFor('standard');
    if (standard != null) {
      final label = language == 'fr' ? standard['labelFr'] : standard['labelEn'];
      if (label != null) {
        return language == 'fr' ? 'A partir de $label' : 'From $label';
      }
    }
    return language == 'fr' ? 'A partir de 9,25 \$ / mois' : 'From \$9.25 / month';
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
    fontFamily = prefs.getString('font_family') ?? fontFamily;
    fontScale = prefs.getDouble('font_scale') ?? fontScale;
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
      fontFamily = user?.fontFamily ?? fontFamily;
      fontScale = user?.fontScale ?? fontScale;
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
    await prefs.setString('font_family', fontFamily);
    await prefs.setDouble('font_scale', fontScale);
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

  Future<String?> updateBibleVersion(String value) async {
    const allowed = {'NIV', 'KJV', 'NLT', 'ESV'};
    final normalized = allowed.contains(value) ? value : 'NIV';
    try {
      user = await api.updateProfile({'bibleVersion': normalized});
      try {
        dailyVerse = await api.getDailyVerse();
      } catch (_) {}
      await _saveSession();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Applies a new font immediately (so it feels instant) and syncs it to
  /// the account in the background. The actual font *file* is fetched and
  /// cached on-device by the `google_fonts` package the first time it's
  /// rendered — this just persists which one the user picked.
  Future<String?> updateFontFamily(String value) async {
    final normalized = isKnownFont(value) ? value : 'Inter';
    fontFamily = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_family', normalized);
    notifyListeners();
    if (user == null) return null;
    try {
      user = await api.updateProfile({'fontFamily': normalized});
      await _saveSession();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateFontScale(double value) async {
    final normalized = value.clamp(0.8, 1.4);
    fontScale = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', normalized);
    notifyListeners();
    if (user == null) return null;
    try {
      user = await api.updateProfile({'fontScale': normalized});
      await _saveSession();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// For accounts that already have a password (email sign-up, or a Google
  /// account that has since linked one) — requires the current password,
  /// same as before.
  Future<String?> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await api.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// For Google-signed-in accounts with no password yet — links a new
  /// password to the account so it can also be used to sign in directly.
  Future<String?> setPassword(String newPassword) async {
    try {
      await api.setPassword(newPassword);
      user = await api.getCurrentUser();
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

  Future<void> updateFullName(String name) async {
    if (name.trim().isEmpty) return;
    try {
      user = await api.updateProfile({'full_name': name.trim()});
      await _saveSession();
      notifyListeners();
    } catch (_) {
      // Non-fatal — onboarding should still be able to continue.
    }
  }

  void nextOnboarding() {
    if (onboardingIndex >= onboardingSteps.length - 1) {
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
      final result = await api.loginWithGoogle(idToken, language: language);
      if (result['requiresVerification'] == true) {
        pendingVerifyEmail = result['email']?.toString();
        _setStage(AppStage.verify);
        return null;
      }
      user = api.cachedUser;
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
      if (error.statusCode == 403 && error.data?['requiresVerification'] == true) {
        pendingVerifyEmail = error.data?['email']?.toString();
        _setStage(AppStage.verify);
        return null;
      }
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
      try {
        moodCheckInToday = await api.getMoodCheckInToday();
      } catch (_) {}
      try {
        dailyManna = await api.getDailyMannaStatus();
      } catch (_) {}
      try {
        todaysDeclaration = await api.getTodaysDeclaration();
      } catch (_) {}
      try {
        prayers = await api.getPrayers();
      } catch (_) {}
      try {
        growthScore = await api.getGrowthScore();
      } catch (_) {}
      try {
        seasonalEvents = await api.getSeasonalEvents();
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

  bool get hasCheckedInToday => moodCheckInToday['checkedIn'] == true;

  Future<void> submitMoodCheckIn(String mood, {String? note}) async {
    await api.logMoodCheckIn(mood, note: note);
    moodCheckInToday = {
      'checkedIn': true,
      'log': {'mood': mood, 'note': note},
    };
    notifyListeners();
  }

  bool get isDailyMannaAvailable => dailyManna['available'] != false;

  Future<Map<String, dynamic>> claimDailyManna() async {
    final result = await api.claimDailyManna();
    dailyManna = {...dailyManna, ...result, 'available': false};
    notifyListeners();
    return result;
  }

  // ── Verse of the Moment ──────────────────────────────────────
  Future<Map<String, dynamic>> fetchRandomVerse() => api.getRandomVerse();

  // ── Prophetic Declarations ───────────────────────────────────
  bool get hasConfirmedDeclarationToday => todaysDeclaration['confirmedToday'] == true;

  Future<void> confirmDeclaration() async {
    final result = await api.confirmDeclaration();
    todaysDeclaration = {...todaysDeclaration, ...result};
    notifyListeners();
  }

  // ── Answered Prayer Wall ──────────────────────────────────────
  List<Map<String, dynamic>> get answeredPrayers =>
      prayers.where((p) => p['is_answered'] == true).toList();

  List<Map<String, dynamic>> get unansweredPrayers =>
      prayers.where((p) => p['is_answered'] != true).toList();

  Future<void> markPrayerAnswered(String prayerId, {String? testimony}) async {
    await api.markPrayerAnswered(prayerId, isAnswered: true, testimony: testimony);
    final index = prayers.indexWhere((p) => p['id'] == prayerId);
    if (index != -1) {
      prayers[index] = {...prayers[index], 'is_answered': true, 'testimony': testimony};
    }
    notifyListeners();
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

  Future<String?> activateGooglePlayBilling({required String tier}) async {
    try {
      final result = await PlayBillingService.instance.purchaseProduct(
        productIdFor(tier),
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

  Future<String?> restoreGooglePlayBilling({required String tier}) async {
    try {
      final result = await PlayBillingService.instance.restoreProductPurchase(
        productIdFor(tier),
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
