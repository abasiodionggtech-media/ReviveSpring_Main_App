class AppUser {
  const AppUser({
    this.id,
    required this.email,
    required this.fullName,
    this.language = 'en',
    this.bibleVersion = 'NIV',
    this.role = 'user',
    this.plan = 'free',
    this.verified = true,
    this.photoUrl,
    this.authProvider = 'email',
    this.hasCompletedOnboarding = false,
    this.timezone = 'UTC',
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.dailyEmailEnabled = true,
    this.pushNotificationsEnabled = true,
  });

  final String? id;
  final String email;
  final String fullName;
  final String language;
  final String bibleVersion;
  final String role;
  final String plan;
  final bool verified;
  final String? photoUrl;
  final String authProvider;
  final bool hasCompletedOnboarding;
  final String timezone;
  final int reminderHour;
  final int reminderMinute;
  final bool dailyEmailEnabled;
  final bool pushNotificationsEnabled;

  bool get isAdmin => role == 'admin';
  bool get isPremium => isAdmin || plan == 'premium';
  bool get isStandard => plan == 'standard';
  bool get isPaidPlan => isPremium || isStandard;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString(),
      email: json['email']?.toString() ?? '',
      fullName: (json['fullName'] ?? json['full_name'] ?? 'Friend').toString(),
      language: (json['language'] ?? 'en').toString(),
      bibleVersion: (json['bibleVersion'] ?? 'NIV').toString(),
      role: json['role']?.toString() ?? 'user',
      plan: (json['subscriptionStatus'] ?? json['plan'] ?? 'free').toString(),
      verified: (json['verified'] ?? json['isEmailVerified']) != false,
      photoUrl: (json['profileImageUrl'] ?? json['profile_image_url'] ?? json['photoUrl'])?.toString(),
      authProvider: (json['authProvider'] ?? json['auth_provider'] ?? 'email').toString(),
      hasCompletedOnboarding: (json['hasCompletedOnboarding'] ?? json['has_completed_onboarding']) == true,
      timezone: (json['timezone'] ?? 'UTC').toString(),
      reminderHour: ((json['reminderHour'] ?? json['registeredHour'] ?? 9) as num).toInt(),
      reminderMinute: ((json['reminderMinute'] ?? 0) as num).toInt(),
      dailyEmailEnabled: (json['dailyEmailEnabled'] ?? true) != false,
      pushNotificationsEnabled: (json['pushNotificationsEnabled'] ?? true) != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'language': language,
        'bibleVersion': bibleVersion,
        'role': role,
        'plan': plan,
        'verified': verified,
        'photoUrl': photoUrl,
        'authProvider': authProvider,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'timezone': timezone,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'dailyEmailEnabled': dailyEmailEnabled,
        'pushNotificationsEnabled': pushNotificationsEnabled,
      };
}
