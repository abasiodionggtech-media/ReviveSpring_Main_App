import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/goal_item.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../models/prayer_response.dart';

class VerseData {
  const VerseData(this.verse, this.ref);

  final String verse;
  final String ref;
}

class OnboardingOption {
  const OnboardingOption(this.emoji, this.label, {this.exclusive = false});

  final String emoji;
  final String label;
  final bool exclusive; // selecting this clears every other option (e.g. "None of these")
}

enum OnboardingStepType {
  tour,
  singleChoice,
  multiChoice,
  reminder,
  emailConfirm,
  profileSetup,
  premium,
  summary,
}

class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.section,
    required this.title,
    this.subtitle,
    this.type = OnboardingStepType.singleChoice,
    this.options = const [],
    this.maxSelect,
    this.optional = false,
  });

  final String id;
  final String section;
  final String title;
  final String? subtitle;
  final OnboardingStepType type;
  final List<OnboardingOption> options;
  final int? maxSelect; // null = unlimited selections for multiChoice
  final bool optional; // step can be skipped without an answer

  bool get isMultiChoice => type == OnboardingStepType.multiChoice;
}

const onboardingSteps = [
  // ─── Section 1 — Welcome ───────────────────────────────────────────────
  OnboardingStep(
    id: 'tour',
    section: 'Welcome',
    title: 'ReviveMe is your daily space for prayer, growth, and peace.',
    type: OnboardingStepType.tour,
    options: [
      OnboardingOption('🙏', 'Prayer'),
      OnboardingOption('📓', 'Journal'),
      OnboardingOption('✅', 'Daily Goals'),
    ],
  ),

  // ─── Section 2 — Faith Background ──────────────────────────────────────
  OnboardingStep(
    id: 'faithJourney',
    section: 'Faith Background',
    title: 'Where are you on your faith journey right now?',
    options: [
      OnboardingOption('🌱', "I'm brand new to Christianity"),
      OnboardingOption('📖', "I'm growing but still learning"),
      OnboardingOption('🌳', "I've walked with God for many years"),
      OnboardingOption('🔄', "I'm returning after a period away"),
      OnboardingOption('🤔', "I'm exploring and not sure yet"),
    ],
  ),
  OnboardingStep(
    id: 'churchConnection',
    section: 'Faith Background',
    title: 'Are you currently connected to a church or faith community?',
    options: [
      OnboardingOption('✅', 'Yes, I attend regularly'),
      OnboardingOption('🔄', 'Sometimes, not consistently'),
      OnboardingOption('🏠', 'I worship on my own at home'),
      OnboardingOption('🔍', "I'm looking for a community"),
      OnboardingOption('❌', 'No, not currently'),
    ],
  ),
  OnboardingStep(
    id: 'bibleFamiliarity',
    section: 'Faith Background',
    title: 'How familiar are you with the Bible?',
    options: [
      OnboardingOption('📗', "I'm just starting to read it"),
      OnboardingOption('📘', 'I know the basics and some stories'),
      OnboardingOption('📙', 'I read it regularly'),
      OnboardingOption('📕', 'I study it deeply and consistently'),
    ],
  ),
  OnboardingStep(
    id: 'salvation',
    section: 'Faith Background',
    title: 'Have you made a personal decision to follow Jesus Christ?',
    options: [
      OnboardingOption('✝️', 'Yes, I have'),
      OnboardingOption('🌱', "I'm not sure — I'd like to know more"),
      OnboardingOption('🙏', "I'd like to make that decision today"),
      OnboardingOption('🤔', "Not yet, but I'm open"),
    ],
  ),

  // ─── Section 3 — Prayer Needs ───────────────────────────────────────────
  OnboardingStep(
    id: 'lifeSeason',
    section: 'Prayer Needs',
    title: 'What best describes your life right now?',
    options: [
      OnboardingOption('🌊', "I'm going through a very difficult season"),
      OnboardingOption('⛅', 'Things are okay but I need more peace'),
      OnboardingOption('☀️', 'Life is good and I want to stay connected'),
      OnboardingOption('🌱', "I'm in a season of new beginnings"),
      OnboardingOption('🔄', "I'm in a transition or major change"),
    ],
  ),
  OnboardingStep(
    id: 'prayerFocus',
    section: 'Prayer Needs',
    title: 'What do you most want to bring to God in prayer?',
    subtitle: 'Choose up to 3',
    type: OnboardingStepType.multiChoice,
    maxSelect: 3,
    options: [
      OnboardingOption('😰', 'Anxiety & fear'),
      OnboardingOption('💔', 'Healing & pain'),
      OnboardingOption('👨‍👩‍👧', 'Family & relationships'),
      OnboardingOption('💰', 'Finances & provision'),
      OnboardingOption('🧭', 'Direction & big decisions'),
      OnboardingOption('💪', 'Strength & perseverance'),
      OnboardingOption('😴', 'Sleep, rest & peace of mind'),
      OnboardingOption('🙌', 'Praise & worship'),
      OnboardingOption('❤️', 'Salvation of a loved one'),
      OnboardingOption('🤝', 'Forgiveness & reconciliation'),
    ],
  ),
  OnboardingStep(
    id: 'emotionalState',
    section: 'Prayer Needs',
    title: 'How are you feeling most days lately?',
    options: [
      OnboardingOption('😟', 'Overwhelmed and heavy'),
      OnboardingOption('😐', 'Okay but going through the motions'),
      OnboardingOption('😌', 'Peaceful but wanting to grow deeper'),
      OnboardingOption('😊', 'Grateful and full of faith'),
      OnboardingOption('😔', 'Lonely or disconnected from God'),
    ],
  ),
  OnboardingStep(
    id: 'mentalWellness',
    section: 'Prayer Needs',
    title: 'Do any of these affect your day-to-day life?',
    subtitle: 'Select all that apply',
    type: OnboardingStepType.multiChoice,
    options: [
      OnboardingOption('😥', 'Anxiety or excessive worry'),
      OnboardingOption('😞', 'Low mood or depression'),
      OnboardingOption('😤', 'Stress and burnout'),
      OnboardingOption('😴', 'Poor sleep'),
      OnboardingOption('😔', 'Grief or loss'),
      OnboardingOption('💭', 'Low self-worth'),
      OnboardingOption('✅', "None of these — I'm doing well", exclusive: true),
    ],
  ),
  OnboardingStep(
    id: 'prayerUrgency',
    section: 'Prayer Needs',
    title: 'Is there something specific you need God to move on right now?',
    options: [
      OnboardingOption('🔥', "Yes — I'm in urgent need"),
      OnboardingOption('🙏', 'Yes — ongoing but not urgent'),
      OnboardingOption('🌿', 'Not specifically — I just want to grow'),
      OnboardingOption('🤲', 'I want to learn how to pray more'),
    ],
  ),

  // ─── Section 4 — Spiritual Goals ────────────────────────────────────────
  OnboardingStep(
    id: 'spiritualGoals',
    section: 'Spiritual Goals',
    title: 'What do you most want ReviveMe to help you with?',
    subtitle: 'Choose up to 2',
    type: OnboardingStepType.multiChoice,
    maxSelect: 2,
    options: [
      OnboardingOption('🔥', 'Build a consistent daily prayer habit'),
      OnboardingOption('📖', 'Know and understand the Bible better'),
      OnboardingOption('☮️', 'Find more peace and calm in life'),
      OnboardingOption('💪', 'Stay strong through a hard season'),
      OnboardingOption('🌟', 'Grow closer to God personally'),
      OnboardingOption('🙌', 'Experience a breakthrough'),
      OnboardingOption('🧘', 'Improve my mental and emotional wellbeing'),
    ],
  ),
  OnboardingStep(
    id: 'commitmentLevel',
    section: 'Spiritual Goals',
    title: 'How much time can you realistically give to prayer each day?',
    options: [
      OnboardingOption('⚡', '5 minutes — short and focused'),
      OnboardingOption('🕐', '10–15 minutes — a meaningful pause'),
      OnboardingOption('🕑', '20–30 minutes — deep and unhurried'),
      OnboardingOption('🕒', 'More than 30 minutes — I want to go deep'),
    ],
  ),
  OnboardingStep(
    id: 'streakMotivation',
    section: 'Spiritual Goals',
    title: 'What keeps you consistent in spiritual habits?',
    options: [
      OnboardingOption('🏆', 'Seeing my progress and streaks'),
      OnboardingOption('🔔', 'Being reminded at the right time'),
      OnboardingOption('📖', 'Having fresh content every day'),
      OnboardingOption('👥', 'Knowing others are praying too'),
      OnboardingOption('🎯', 'Having a clear goal to work toward'),
    ],
  ),
  OnboardingStep(
    id: 'journeyType',
    section: 'Spiritual Goals',
    title: 'What kind of prayer experience do you prefer?',
    options: [
      OnboardingOption('📝', 'Written prayers I can read and follow'),
      OnboardingOption('📖', 'A Bible verse to sit with and reflect on'),
      OnboardingOption('🎯', 'A short daily action step to live out'),
      OnboardingOption('🎙️', 'Free, guided conversation with AI'),
      OnboardingOption('🔀', 'A healthy mix of all of the above'),
    ],
  ),

  // ─── Section 5 — Daily Rhythm ───────────────────────────────────────────
  OnboardingStep(
    id: 'bestPrayerTime',
    section: 'Daily Rhythm',
    title: 'When do you feel most open to prayer?',
    options: [
      OnboardingOption('🌅', 'Early morning — before the day begins'),
      OnboardingOption('☀️', "Mid-morning — once I've settled in"),
      OnboardingOption('🌤️', 'Afternoon — midday reset'),
      OnboardingOption('🌆', 'Evening — winding down'),
      OnboardingOption('🌙', 'Night — quiet before bed'),
      OnboardingOption('🔀', 'It varies for me'),
    ],
  ),
  OnboardingStep(
    id: 'reminderTime',
    section: 'Daily Rhythm',
    title: 'Set your daily prayer reminder',
    type: OnboardingStepType.reminder,
  ),
  OnboardingStep(
    id: 'notificationPreference',
    section: 'Daily Rhythm',
    title: 'How would you like ReviveMe to reach you?',
    options: [
      OnboardingOption('🔔', 'Push notifications on my phone'),
      OnboardingOption('📧', 'Daily prayer email'),
      OnboardingOption('📲', 'Both push and email'),
      OnboardingOption('🔕', "Neither — I'll open the app myself"),
    ],
  ),
  OnboardingStep(
    id: 'email',
    section: 'Daily Rhythm',
    title: 'Your daily prayer email will go to:',
    type: OnboardingStepType.emailConfirm,
  ),

  // ─── Section 6 — Faith Personalization ─────────────────────────────────
  OnboardingStep(
    id: 'denomination',
    section: 'Faith Personalization',
    title: 'Which best describes your Christian background?',
    subtitle: 'Optional',
    optional: true,
    options: [
      OnboardingOption('✝️', 'Catholic'),
      OnboardingOption('🕊️', 'Protestant / Evangelical'),
      OnboardingOption('🙌', 'Pentecostal / Charismatic'),
      OnboardingOption('✝️', 'Orthodox'),
      OnboardingOption('🌍', 'African Traditional Christian'),
      OnboardingOption('🌐', 'Non-denominational'),
      OnboardingOption('🤷', 'Not sure / Prefer not to say'),
    ],
  ),
  OnboardingStep(
    id: 'prayerLanguageStyle',
    section: 'Faith Personalization',
    title: 'When you read a prayer, what tone feels most natural?',
    options: [
      OnboardingOption('🤝', 'Conversational — like talking to a friend'),
      OnboardingOption('📜', 'Traditional — formal and reverent'),
      OnboardingOption('🔥', 'Bold & declarative — strong faith confessions'),
      OnboardingOption('🌊', 'Gentle & reflective — quiet and meditative'),
    ],
  ),
  OnboardingStep(
    id: 'scripturePreference',
    section: 'Faith Personalization',
    title: 'Which Bible translation do you prefer?',
    options: [
      OnboardingOption('📖', 'NIV — easy to understand'),
      OnboardingOption('📖', 'KJV — classic and traditional'),
      OnboardingOption('📖', 'NLT — simple, everyday language'),
      OnboardingOption('📖', 'ESV — precise and modern'),
      OnboardingOption('📖', 'No preference — surprise me'),
    ],
  ),
  OnboardingStep(
    id: 'testimonialIntent',
    section: 'Faith Personalization',
    title: 'Would you like to track answered prayers?',
    options: [
      OnboardingOption('✅', 'Yes — I want to mark prayers as answered'),
      OnboardingOption('📓', 'Yes — and write a brief testimony when they are'),
      OnboardingOption('🔄', 'Maybe later'),
      OnboardingOption('❌', 'No, not for me'),
    ],
  ),

  // ─── Section 7 — Final Steps ────────────────────────────────────────────
  OnboardingStep(
    id: 'profile',
    section: 'Final Steps',
    title: 'How should we address you in your prayers?',
    type: OnboardingStepType.profileSetup,
  ),
  OnboardingStep(
    id: 'premiumChoice',
    section: 'Final Steps',
    title: 'Unlock everything ReviveMe has to offer',
    subtitle: 'Unlimited AI chat · Mental Wellness content · No ads',
    type: OnboardingStepType.premium,
  ),
  OnboardingStep(
    id: 'summary',
    section: 'Final Steps',
    title: "You're ready! 🎉",
    type: OnboardingStepType.summary,
  ),
];

const moods = [
  Mood(id: 'anxious', en: 'Anxious', fr: 'Anxieux', icon: Icons.air, color: AppColors.sky),
  Mood(id: 'financial_stress', en: 'Financial Stress', fr: 'Stress Financier', icon: Icons.monetization_on_outlined, color: AppColors.deepEmerald),
  Mood(id: 'sad', en: 'Sad', fr: 'Triste', icon: Icons.cloudy_snowing, color: AppColors.lavender),
  Mood(id: 'confused', en: 'Confused', fr: 'Confus', icon: Icons.explore_outlined, color: AppColors.coral),
  Mood(id: 'grateful', en: 'Grateful', fr: 'Reconnaissant', icon: Icons.auto_awesome, color: AppColors.leaf),
  Mood(id: 'healing', en: 'Healing', fr: 'Guerison', icon: Icons.healing_outlined, color: AppColors.leaf),
  Mood(id: 'need_job', en: 'Need a Job', fr: "Besoin d'Emploi", icon: Icons.work_outline, color: AppColors.sky),
  Mood(id: 'protection', en: 'Protection', fr: 'Protection', icon: Icons.shield_outlined, color: AppColors.deepEmerald),
  Mood(id: 'need_peace', en: 'Need Peace', fr: 'Besoin de Paix', icon: Icons.self_improvement, color: AppColors.sky),
  Mood(id: 'lonely', en: 'Lonely', fr: 'Seul', icon: Icons.person_outline, color: AppColors.sky),
  Mood(id: 'overwhelmed', en: 'Overwhelmed', fr: 'Submerge', icon: Icons.waves_outlined, color: AppColors.coral),
  Mood(id: 'tired', en: 'Tired', fr: 'Fatigue', icon: Icons.bedtime_outlined, color: AppColors.lavender),
  Mood(id: 'hopeful', en: 'Hopeful', fr: 'Plein Espoir', icon: Icons.wb_sunny_outlined, color: AppColors.leaf),
  Mood(id: 'joyful', en: 'Joyful', fr: 'Joyeux', icon: Icons.sentiment_very_satisfied_outlined, color: AppColors.sky),
  Mood(id: 'tempted', en: 'Tempted', fr: 'Tente', icon: Icons.local_fire_department_outlined, color: AppColors.deepEmerald),
  Mood(id: 'discouraged', en: 'Discouraged', fr: 'Decourage', icon: Icons.eco_outlined, color: AppColors.coral),
  Mood(id: 'wisdom', en: 'Seeking Wisdom', fr: 'Cherche Sagesse', icon: Icons.lightbulb_outline, color: AppColors.leaf),
  Mood(id: 'family', en: 'Family Concern', fr: 'Souci Familial', icon: Icons.favorite_outline, color: AppColors.deepEmerald),
];

String normalizeMoodId(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  return switch (normalized) {
    'financial' || 'financial_stress' || 'money' => 'financial_stress',
    'job' || 'need_a_job' || 'need_job' => 'need_job',
    'peace' || 'need_peace' => 'need_peace',
    'seeking_wisdom' || 'wisdom' => 'wisdom',
    'family_concern' || 'family' => 'family',
    _ => normalized,
  };
}

Mood moodForId(String id) {
  final normalized = normalizeMoodId(id);
  return moods.firstWhere(
    (mood) => mood.id == normalized,
    orElse: () => const Mood(id: 'guided', en: 'Guided Prayer', fr: 'Priere Guidee', icon: Icons.favorite_outline, color: AppColors.leaf),
  );
}

const dailyVerses = [
  VerseData('The Lord is my shepherd; I shall not want.', 'Psalm 23:1'),
  VerseData('I can do all things through Christ who strengthens me.', 'Philippians 4:13'),
  VerseData('Trust in the Lord with all your heart.', 'Proverbs 3:5'),
  VerseData('Be strong and courageous. Do not be afraid.', 'Joshua 1:9'),
  VerseData('The Lord is close to the brokenhearted.', 'Psalm 34:18'),
];

VerseData verseForToday([DateTime? now]) {
  final date = now ?? DateTime.now();
  return dailyVerses[date.day % dailyVerses.length];
}

final prayerResponses = <String, PrayerResponse>{
  'anxious': const PrayerResponse(
    encouragement: 'God holds tomorrow in His hands. You are not alone in this moment.',
    verse: 'Cast all your anxiety on Him because He cares for you.',
    ref: '1 Peter 5:7',
    prayer:
        'Heavenly Father, I release every fear into Your loving hands. Calm my spirit, quiet my mind, and fill me with Your peace that surpasses understanding. Help me breathe deeply in Your presence and trust You with the next step. Amen.',
    action: "Take 5 deep breaths and repeat: 'God is with me. I am safe. I am held.'",
  ),
  'financial_stress': const PrayerResponse(
    encouragement: 'God is your provider. Every need you have is known to Him.',
    verse: 'My God will meet all your needs according to the riches of his glory.',
    ref: 'Philippians 4:19',
    prayer:
        'Gracious Father, open doors of provision I have not yet seen. Give me wisdom to manage what I have and peace as I wait on Your timing. Amen.',
    action: 'Write down three things God has already provided for you.',
  ),
  'sad': const PrayerResponse(
    encouragement: 'Your tears are not invisible to God. He is near.',
    verse: 'The Lord is close to the brokenhearted.',
    ref: 'Psalm 34:18',
    prayer:
        'Dear Lord, my heart is heavy today. Come close to me and let Your comfort wash over me. Remind me that joy can rise again. Amen.',
    action: 'Listen to one uplifting worship song and let it minister to your spirit.',
  ),
  'grateful': const PrayerResponse(
    encouragement: 'Your gratitude is a powerful seed. Keep planting it.',
    verse: 'Give thanks to the Lord, for he is good.',
    ref: 'Psalm 107:1',
    prayer:
        'Wonderful Lord, today my heart overflows with gratitude. Thank You for breath, mercy, love, and grace that meets me again. Amen.',
    action: 'Tell someone about one blessing God has given you.',
  ),
  'need_peace': const PrayerResponse(
    encouragement: 'The Prince of Peace is here. Let Him still every storm in your heart.',
    verse: 'Peace I leave with you; my peace I give you.',
    ref: 'John 14:27',
    prayer:
        'Prince of Peace, speak to the storms in my life. Quiet my heart and help me receive the peace only You can give. Amen.',
    action: 'Spend 10 minutes in silence today. No phone, just breathe with God.',
  ),
};

final seedGoals = [
  GoalItem(text: 'Pray for family', done: true),
  GoalItem(text: 'Read Psalm 23'),
  GoalItem(text: 'Write one gratitude note'),
];

final seedJournal = [
  JournalEntry(body: 'Thankful for peace this morning.', createdAt: DateTime.now()),
  JournalEntry(body: 'Praying for wisdom and courage.', createdAt: DateTime.now()),
];

String fallbackAiPrayer(String prompt) {
  if (prompt.toLowerCase().contains('family')) {
    return 'Lord, cover my family with patience, protection, unity, and kindness. Teach us to listen well, forgive quickly, and walk together in love.';
  }
  if (prompt.toLowerCase().contains('forgive')) {
    return 'Father, soften my heart without ignoring my pain. Give me wisdom, boundaries, and grace to release what has been heavy.';
  }
  if (prompt.toLowerCase().contains('hope')) {
    return 'God of renewal, breathe hope into the places that feel tired. Remind me that this chapter is held by Your mercy.';
  }
  return 'Lord, meet me in this anxious moment. Slow my breathing, steady my thoughts, and help me remember that I am not alone.';
}
