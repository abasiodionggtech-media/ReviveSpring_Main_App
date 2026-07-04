import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../data/app_data.dart';
import '../../models/mood.dart';
import '../../models/prayer_response.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/content_tiles.dart';
import '../../widgets/section_header.dart';
import 'home_screen.dart';

class PrayerLibraryScreen extends StatelessWidget {
  const PrayerLibraryScreen({
    super.key,
    required this.controller,
    required this.onOpenAi,
  });
  final AppController controller;
  final VoidCallback onOpenAi;

  @override
  Widget build(BuildContext context) {
    final remote = controller.prayerLibrary;
    final items = remote.isNotEmpty
        ? remote
        : [
            {
              'titleEn': 'Morning Renewal',
              'prayerEn':
                  'Lord, align my heart with peace, wisdom, and courage today.',
              'category': 'morning',
            },
            {
              'titleEn': 'Anxiety Support',
              'prayerEn': 'A quiet prayer for calm breathing and steady faith.',
              'category': 'anxious',
            },
            {
              'titleEn': 'Healing',
              'prayerEn': 'A hopeful prayer for body, mind, and relationships.',
              'category': 'healing',
            },
            {
              'titleEn': 'Family',
              'prayerEn': 'Cover the people I love with unity and grace.',
              'category': 'family',
            },
          ];
    return ListView(
      key: const ValueKey('prayer'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        const SectionHeader(
          title: 'Prayer Library',
          subtitle: 'Saved prayers and guided moments.',
          icon: Icons.menu_book,
        ),
        const SizedBox(height: 18),
        AnimatedPrimaryButton(
          label: 'Ask AI Prayer Companion',
          icon: Icons.auto_awesome,
          onPressed: onOpenAi,
        ),
        const SizedBox(height: 18),
        ...items.map((item) {
          final mood = item['category']?.toString() ?? 'guided';
          final moodData = moodForId(mood);
          final response = PrayerResponse(
            encouragement: item['titleEn']?.toString() ?? 'A guided prayer',
            verse:
                item['verseEn']?.toString() ??
                'The Lord is near to all who call on Him.',
            ref: item['verseRef']?.toString() ?? 'Psalm 145:18',
            prayer: item['prayerEn']?.toString() ?? '',
            action:
                item['actionEn']?.toString() ?? 'Take a quiet moment with God.',
          );
          return PrayerTile(
            title: response.encouragement,
            body: response.prayer,
            icon: moodData.icon,
            color: moodData.color,
            onTap: () => _openPrayerDetails(
              context,
              normalizeMoodId(mood),
              response,
              moodData,
            ),
          );
        }),
      ],
    );
  }

  void _openPrayerDetails(
    BuildContext context,
    String mood,
    PrayerResponse response,
    Mood moodData,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PrayerDetailSheet(
        mood: mood,
        moodData: moodData,
        response: response,
        controller: controller,
      ),
    );
  }
}

class _PrayerDetailSheet extends StatelessWidget {
  const _PrayerDetailSheet({
    required this.mood,
    required this.moodData,
    required this.response,
    required this.controller,
  });

  final String mood;
  final Mood moodData;
  final PrayerResponse response;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final experience = _prayerExperience(mood, response);
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .42,
      maxChildSize: .92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FBF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: moodData.color.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: moodData.color.withValues(alpha: .22),
                    ),
                  ),
                  child: Icon(moodData.icon, color: moodData.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    response.encouragement,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'A complete spiritual support experience for this season.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            _PrayerResourceCard(
              number: '01',
              title: 'Relevant Scriptures',
              icon: Icons.menu_book_outlined,
              child: Column(
                children: [
                  for (final scripture in experience.scriptures) ...[
                    _ScriptureQuote(
                      verse: scripture.$1,
                      reference: scripture.$2,
                    ),
                    if (scripture != experience.scriptures.last)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            _PrayerResourceCard(
              number: '02',
              title: 'Faith Confessions',
              icon: Icons.record_voice_over_outlined,
              child: _BulletList(
                items: experience.confessions,
                icon: Icons.check_circle_outline,
              ),
            ),
            _PrayerResourceCard(
              number: '03',
              title: 'Guided Prayer',
              icon: Icons.volunteer_activism_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.guidedPrayer,
                    style: const TextStyle(
                      height: 1.6,
                      color: AppColors.ink,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.leaf.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Faith Step',
                          style: TextStyle(
                            color: AppColors.deepEmerald,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          response.action,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _PrayerResourceCard(
              number: '04',
              title: 'Words of Encouragement and Hope',
              icon: Icons.wb_sunny_outlined,
              child: _BulletList(
                items: experience.encouragement,
                icon: Icons.auto_awesome,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedPrimaryButton(
              label: 'Start Timed Prayer',
              icon: Icons.play_arrow,
              onPressed: () {
                Navigator.of(context).pop();
                showDialog<void>(
                  context: context,
                  builder: (_) => CenteredTimedPrayer(
                    mood: mood,
                    response: response,
                    controller: controller,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerExperience {
  const _PrayerExperience({
    required this.scriptures,
    required this.confessions,
    required this.guidedPrayer,
    required this.encouragement,
  });

  final List<(String, String)> scriptures;
  final List<String> confessions;
  final String guidedPrayer;
  final List<String> encouragement;
}

_PrayerExperience _prayerExperience(String mood, PrayerResponse response) {
  final topic = '$mood ${response.encouragement}'.toLowerCase();
  final anxiety = topic.contains('anx');
  final healing = topic.contains('heal');
  final family = topic.contains('family');
  final morning = topic.contains('morning') || topic.contains('renewal');
  final scriptures = anxiety
      ? const [
          (
            'Cast all your care upon him; for he careth for you.',
            '1 Peter 5:7',
          ),
          (
            'The peace of God... shall keep your hearts and minds through Christ Jesus.',
            'Philippians 4:7',
          ),
          ('What time I am afraid, I will trust in thee.', 'Psalm 56:3'),
        ]
      : healing
      ? const [
          ('With his stripes we are healed.', 'Isaiah 53:5'),
          ('Heal me, O Lord, and I shall be healed.', 'Jeremiah 17:14'),
          (
            'He healeth the broken in heart, and bindeth up their wounds.',
            'Psalm 147:3',
          ),
        ]
      : family
      ? const [
          ('As for me and my house, we will serve the Lord.', 'Joshua 24:15'),
          (
            'Above all things have fervent charity among yourselves.',
            '1 Peter 4:8',
          ),
          ('Blessed are the peacemakers.', 'Matthew 5:9'),
        ]
      : morning
      ? const [
          (
            'Cause me to hear thy lovingkindness in the morning; for in thee do I trust.',
            'Psalm 143:8',
          ),
          (
            'They are new every morning: great is thy faithfulness.',
            'Lamentations 3:23',
          ),
          ('This is the day which the Lord hath made.', 'Psalm 118:24'),
        ]
      : [
          (response.verse, response.ref),
          const (
            'God is our refuge and strength, a very present help in trouble.',
            'Psalm 46:1',
          ),
        ];
  final confessions = anxiety
      ? const [
          'God\'s peace guards my heart and mind.',
          'I release the future and receive grace for this moment.',
          'Fear may speak, but it does not lead me; the Spirit of God does.',
        ]
      : healing
      ? const [
          'God is present in every part of my healing journey.',
          'My pain is seen, and restoration is still possible.',
          'I receive strength for today and hope for tomorrow.',
        ]
      : family
      ? const [
          'God\'s wisdom and peace are welcome in my home.',
          'I choose patient words, forgiveness, and faithful love.',
          'My family is held in God\'s care even when I cannot control every outcome.',
        ]
      : const [
          'God is with me, guiding me with wisdom and grace.',
          'I can take today\'s next faithful step without fear.',
          'My hope is rooted in God\'s unchanging love.',
        ];
  final encouragement = anxiety
      ? const [
          'You do not need to solve everything before you can breathe.',
          'Peace can arrive in small moments: one breath, one verse, one honest prayer.',
          'Needing support is not weak faith. God often brings care through safe people.',
        ]
      : const [
          'Growth is still happening in the quiet places you cannot yet measure.',
          'God meets honest hearts, not perfect performances.',
          'A small faithful response today can become tomorrow\'s stronger rhythm.',
        ];
  return _PrayerExperience(
    scriptures: scriptures,
    confessions: confessions,
    guidedPrayer: response.prayer,
    encouragement: encouragement,
  );
}

class _PrayerResourceCard extends StatelessWidget {
  const _PrayerResourceCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String number;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.deepEmerald.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: AppColors.leaf, size: 21),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.deepEmerald,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ScriptureQuote extends StatelessWidget {
  const _ScriptureQuote({required this.verse, required this.reference});
  final String verse;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.iconCream.withValues(alpha: .56),
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: AppColors.leaf, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$verse"',
            style: const TextStyle(
              color: AppColors.ink,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            reference,
            style: const TextStyle(
              color: AppColors.leaf,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.icon});
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.leaf, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.ink,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
