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

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.title,
    this.body,
    required this.icon,
    required this.color,
    this.kind = OnboardingSlideKind.info,
    this.options = const [],
    this.multiSelect = false,
    this.statement,
    this.primaryLabel,
  });

  final String title;
  final String? body;
  final IconData icon;
  final Color color;
  final OnboardingSlideKind kind;
  final List<String> options;
  final bool multiSelect;
  final String? statement;
  final String? primaryLabel;
}

enum OnboardingSlideKind { info, topic, chart, multiChoice, statement, singleChoice, reminder, summary, builder, commit }

const onboardingSlides = [
  OnboardingSlideData(
    title: "This is what's possible when Scripture meets real life",
    body: 'Stories from people finding joy, purpose, and direction with daily guidance.',
    icon: Icons.reviews_outlined,
    color: AppColors.deepEmerald,
    kind: OnboardingSlideKind.info,
  ),
  OnboardingSlideData(
    title: 'Every journey of faith is unique',
    body: "We'll help you create a path that fits your life, not someone else's.",
    icon: Icons.church_outlined,
    color: AppColors.leaf,
    primaryLabel: "Let's walk together",
  ),
  OnboardingSlideData(
    title: 'Which topic would you like to explore first?',
    body: 'This will not limit your experience with ReviveSpring.',
    icon: Icons.explore_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.topic,
    options: ['Biblical Self Discovery', 'Build Unshakable Faith', 'Parenting', 'Financial Peace', 'Other'],
  ),
  OnboardingSlideData(
    title: "You've already taken a powerful step",
    body: '86% of users who focused on one topic in their first month found more peace, clarity, and direction.',
    icon: Icons.bar_chart,
    color: AppColors.sky,
    kind: OnboardingSlideKind.chart,
  ),
  OnboardingSlideData(
    title: 'What motivates you to grow spiritually?',
    body: 'Select all that apply',
    icon: Icons.spa_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.multiChoice,
    multiSelect: true,
    options: ['Becoming a better person', 'Finding deeper meaning', 'Helping others', 'Overcoming struggles', 'Other'],
  ),
  OnboardingSlideData(
    title: 'Do you agree with this statement?',
    statement: 'Spending time on spiritual growth makes my life feel balanced.',
    icon: Icons.format_quote,
    color: AppColors.deepEmerald,
    kind: OnboardingSlideKind.statement,
    options: ['No', 'Yes'],
  ),
  OnboardingSlideData(
    title: 'Do you agree with this statement?',
    statement: "I think the Bible has answers to most of life's questions, but at times, I come across passages that are hard to interpret.",
    icon: Icons.format_quote,
    color: AppColors.deepEmerald,
    kind: OnboardingSlideKind.statement,
    options: ['No', 'Yes'],
  ),
  OnboardingSlideData(
    title: 'When Scripture feels confusing, we are here to help',
    body: 'Faith, questions, and the hard days too.',
    icon: Icons.chat_bubble_outline,
    color: AppColors.leaf,
  ),
  OnboardingSlideData(
    title: 'Have you ever struggled to live out your beliefs?',
    icon: Icons.directions_walk,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.singleChoice,
    options: ['Yes, all the time', 'Sometimes', 'Rarely', 'Never'],
  ),
  OnboardingSlideData(
    title: 'Shift from knowing to living',
    body: 'Stories from people who felt just like you do now and where they are today.',
    icon: Icons.auto_stories_outlined,
    color: AppColors.leaf,
  ),
  OnboardingSlideData(
    title: 'Does this sound familiar?',
    statement: "I often find my mind wandering when I'm trying to focus on reading.",
    icon: Icons.format_quote,
    color: AppColors.deepEmerald,
    kind: OnboardingSlideKind.statement,
    options: ['Not really', "That's me"],
  ),
  OnboardingSlideData(
    title: 'How often does life feel too busy for quiet time with God?',
    icon: Icons.schedule_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.singleChoice,
    options: ['All the time', 'Sometimes', 'Rarely', 'Never'],
  ),
  OnboardingSlideData(
    title: "Small moments, lasting peace - that's our promise to you",
    body: "Five minutes each morning to center your heart and carry God's presence through your day.",
    icon: Icons.favorite_outline,
    color: AppColors.sky,
  ),
  OnboardingSlideData(
    title: 'How do you usually find God in your day?',
    body: 'Select all that apply',
    icon: Icons.light_mode_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.multiChoice,
    multiSelect: true,
    options: ['Prayer', 'Worship music', 'Reading the Bible', 'Reflecting in nature', 'Journaling my thoughts', 'Other'],
  ),
  OnboardingSlideData(
    title: 'What if Scripture came to you in your hardest moments?',
    body: 'Verses chosen for your struggles, with wisdom that turns pain into purpose.',
    icon: Icons.menu_book_outlined,
    color: AppColors.leaf,
  ),
  OnboardingSlideData(
    title: 'Which of these describes your ideal devotional experience?',
    icon: Icons.tune_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.singleChoice,
    options: ['Simple and actionable', 'Deep and thought-provoking', 'Uplifting and inspiring', 'Guided and structured'],
  ),
  OnboardingSlideData(
    title: 'However you like to connect, we meet you there',
    body: 'Read, listen, reflect, and grow at your pace.',
    icon: Icons.headphones_outlined,
    color: AppColors.leaf,
  ),
  OnboardingSlideData(
    title: "And we don't just add to your reading list - we change how you live",
    body: 'Short, relevant devotionals that make Scripture applicable and easy.',
    icon: Icons.reviews_outlined,
    color: AppColors.leaf,
  ),
  OnboardingSlideData(
    title: 'How much time are you willing to dedicate to your spiritual growth?',
    icon: Icons.timer_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.singleChoice,
    options: ['5 min/day - Short', '10 min/day - Average', '15 min/day - Significant', '20 min/day - Dedicated'],
  ),
  OnboardingSlideData(
    title: 'It takes just 21 days to form a new spiritual routine!',
    body: 'A simple daily rhythm will help you stay on track and keep your goals in view.',
    icon: Icons.schedule_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.reminder,
  ),
  OnboardingSlideData(
    title: 'What can we help you do?',
    body: 'This will not limit your experience with ReviveSpring.',
    icon: Icons.checklist_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.multiChoice,
    multiSelect: true,
    options: [
      "Hear God's voice more clearly",
      'Find my calling and next steps',
      'Understand scripture more deeply',
      'Heal from past hurts',
      'Break free from destructive patterns',
      'Align my life with my beliefs',
    ],
  ),
  OnboardingSlideData(
    title: "Got it! We'll help you:",
    body: 'Understand scripture more deeply',
    icon: Icons.task_alt,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.summary,
  ),
  OnboardingSlideData(
    title: "Scripture becomes life here! Let's build your daily rhythm",
    body: 'Daily prayer, Scripture, quizzes, and one-time actions shaped for you.',
    icon: Icons.dashboard_customize_outlined,
    color: AppColors.leaf,
  ),
  OnboardingSlideData(
    title: 'Creating your personal path...',
    body: 'Setting goals',
    icon: Icons.route_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.builder,
    statement: 'Are you inclined to finish what you start?',
    options: ['No', 'Yes'],
  ),
  OnboardingSlideData(
    title: 'Creating your personal path...',
    body: 'Adapting growth areas',
    icon: Icons.route_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.builder,
    statement: 'Do you tend to stray from the path when faced with challenges?',
    options: ['No', 'Yes'],
  ),
  OnboardingSlideData(
    title: 'Creating your personal path...',
    body: 'Picking content',
    icon: Icons.route_outlined,
    color: AppColors.leaf,
    kind: OnboardingSlideKind.builder,
    statement: 'Do you find it challenging to find the right Bible verse?',
    options: ['No', 'Yes'],
  ),
  OnboardingSlideData(
    title: 'Commitment pact',
    body: "This isn't a big vow - it's a small yes to growing with God.",
    icon: Icons.touch_app_outlined,
    color: AppColors.deepEmerald,
    kind: OnboardingSlideKind.commit,
    primaryLabel: 'Enter ReviveSpring',
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
