import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_controller.dart';
import '../core/app_stage.dart';
import '../data/app_data.dart';
import '../widgets/app_buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Map<int, Set<String>> answers = {};
  bool committed = false;
  bool commitFxActive = false;
  bool commitFlowBusy = false;
  int commitFxSeed = 0;
  Offset commitFxOrigin = const Offset(0, 0);
  int reminderHour = 9;
  int reminderMinute = 0;

  AppController get controller => widget.controller;
  OnboardingSlideData get slide => onboardingSlides[controller.onboardingIndex];

  bool get needsAnswer {
    return switch (slide.kind) {
      OnboardingSlideKind.topic ||
      OnboardingSlideKind.multiChoice ||
      OnboardingSlideKind.singleChoice ||
      OnboardingSlideKind.statement ||
      OnboardingSlideKind.builder => true,
      _ => false,
    };
  }

  bool get canContinue {
    if (slide.kind == OnboardingSlideKind.commit) return committed;
    if (!needsAnswer) return true;
    return (answers[controller.onboardingIndex] ?? {}).isNotEmpty;
  }

  void toggleAnswer(String option) {
    setState(() {
      final selected = answers.putIfAbsent(
        controller.onboardingIndex,
        () => <String>{},
      );
      if (slide.multiSelect) {
        selected.contains(option)
            ? selected.remove(option)
            : selected.add(option);
      } else {
        selected
          ..clear()
          ..add(option);
      }
    });
  }

  Future<void> continueFlow() async {
    if (!canContinue) return;
    if (controller.onboardingIndex == onboardingSlides.length - 1) {
      await controller.saveOnboarding({
        for (final entry in answers.entries)
          'slide_${entry.key}': entry.value.toList(),
        'committed': committed,
        'reminderTime': {
          'hour': reminderHour,
          'minute': reminderMinute,
          'timezone': DateTime.now().timeZoneName,
          'dailyEmailEnabled': true,
          'pushNotificationsEnabled': false,
        },
      });
      controller.go(AppStage.app);
    } else {
      controller.nextOnboarding();
    }
  }

  Future<void> commitWithTransition(Offset? origin) async {
    if (commitFlowBusy) return;
    commitFlowBusy = true;
    if (mounted) {
      setState(() {
        committed = true;
        commitFxActive = true;
        commitFxSeed += 1;
        commitFxOrigin =
            origin ?? (MediaQuery.sizeOf(context).center(Offset.zero));
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 860));
    await continueFlow();
    if (mounted) {
      setState(() => commitFxActive = false);
    }
    commitFlowBusy = false;
  }

  @override
  Widget build(BuildContext context) {
    final index = controller.onboardingIndex;
    final isLast = index == onboardingSlides.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF121715),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
          child: Stack(
            children: [
              Column(
                children: [
                  _OnboardingHeader(
                    index: index,
                    total: onboardingSlides.length,
                    onBack: index == 0 || commitFxActive
                        ? null
                        : controller.previousOnboarding,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _OnboardingBody(
                        key: ValueKey(index),
                        slide: slide,
                        index: index,
                        selected: answers[index] ?? <String>{},
                        committed: committed,
                        onSelected: toggleAnswer,
                        onCommitted: commitWithTransition,
                        reminderHour: reminderHour,
                        reminderMinute: reminderMinute,
                        onReminderChanged: (hour, minute) => setState(() {
                          reminderHour = hour;
                          reminderMinute = minute;
                        }),
                      ),
                    ),
                  ),
                  AnimatedPrimaryButton(
                    label:
                        slide.primaryLabel ??
                        (isLast ? 'Enter ReviveSpring' : 'Continue'),
                    icon: Icons.arrow_forward,
                    onPressed: (canContinue && !commitFxActive)
                        ? continueFlow
                        : null,
                  ),
                ],
              ),
              if (commitFxActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(commitFxSeed),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 860),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        final radius =
                            36 +
                            (MediaQuery.sizeOf(context).longestSide *
                                1.8 *
                                value);
                        return Stack(
                          children: [
                            Positioned(
                              left: commitFxOrigin.dx - radius,
                              top: commitFxOrigin.dy - radius,
                              child: Container(
                                width: radius * 2,
                                height: radius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFF2FA06D,
                                      ).withValues(alpha: 0.95),
                                      AppColors.deepEmerald.withValues(
                                        alpha: 0.96,
                                      ),
                                      AppColors.deepEmerald.withValues(
                                        alpha: 0.88,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: ColoredBox(
                                color: AppColors.deepEmerald.withValues(
                                  alpha: value * 0.7,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.index,
    required this.total,
    required this.onBack,
  });

  final int index;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          color: AppColors.iconCream,
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'About you',
                style: TextStyle(
                  color: AppColors.iconCream,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (index + 1) / total,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: .12),
                  color: AppColors.iconCream,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody({
    super.key,
    required this.slide,
    required this.index,
    required this.selected,
    required this.committed,
    required this.onSelected,
    required this.onCommitted,
    required this.reminderHour,
    required this.reminderMinute,
    required this.onReminderChanged,
  });

  final OnboardingSlideData slide;
  final int index;
  final Set<String> selected;
  final bool committed;
  final ValueChanged<String> onSelected;
  final ValueChanged<Offset?> onCommitted;
  final int reminderHour;
  final int reminderMinute;
  final void Function(int hour, int minute) onReminderChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.iconCream,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (slide.body != null &&
            slide.kind != OnboardingSlideKind.builder &&
            slide.kind != OnboardingSlideKind.commit) ...[
          const SizedBox(height: 14),
          Text(
            slide.body!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.iconCream.withValues(alpha: .58),
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 36),
        switch (slide.kind) {
          OnboardingSlideKind.topic ||
          OnboardingSlideKind.multiChoice ||
          OnboardingSlideKind.singleChoice => _OptionList(
            slide: slide,
            selected: selected,
            onSelected: onSelected,
          ),
          OnboardingSlideKind.statement => _StatementChoice(
            slide: slide,
            selected: selected,
            onSelected: onSelected,
          ),
          OnboardingSlideKind.chart => const _ChartCard(),
          OnboardingSlideKind.reminder => _ReminderCard(
            hour: reminderHour,
            minute: reminderMinute,
            onChanged: onReminderChanged,
          ),
          OnboardingSlideKind.summary => _SummaryCard(slide: slide),
          OnboardingSlideKind.builder => _BuilderCard(
            slide: slide,
            index: index,
            selected: selected,
            onSelected: onSelected,
          ),
          OnboardingSlideKind.commit => _CommitCard(
            committed: committed,
            onCommitted: onCommitted,
          ),
          OnboardingSlideKind.info => _InfoCard(slide: slide, index: index),
        },
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.slide, required this.index});

  final OnboardingSlideData slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (slide.icon == Icons.reviews_outlined) {
      return Column(
        children: const [
          _ReviewCard(
            name: 'Carol',
            text:
                'I used to feel lost trying to study the Bible. Now, every morning I wake up filled with joy and purpose.',
          ),
          SizedBox(height: 14),
          _ReviewCard(
            name: 'Alex',
            text:
                "This app speaks to my heart where I'm at and helps me build a real relationship with God.",
          ),
          SizedBox(height: 14),
          _ReviewCard(
            name: 'Mike',
            text:
                'It breaks spiritual growth into bite-size steps I can actually live out each day.',
          ),
        ],
      );
    }

    return Column(
      children: [
        _Illustration(icon: slide.icon, color: slide.color, index: index),
        const SizedBox(height: 24),
        if (slide.body != null)
          Text(
            slide.body!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.iconCream.withValues(alpha: .62),
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.slide,
    required this.selected,
    required this.onSelected,
  });

  final OnboardingSlideData slide;
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in slide.options) ...[
          _OptionTile(
            label: option,
            checked: selected.contains(option),
            square: slide.multiSelect,
            onTap: () => onSelected(option),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.checked,
    required this.square,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final bool square;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
        decoration: BoxDecoration(
          color: checked
              ? AppColors.deepEmerald.withValues(alpha: .48)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: checked
                ? AppColors.iconCream.withValues(alpha: .46)
                : Colors.white.withValues(alpha: .18),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.iconCream,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: checked ? AppColors.iconCream : Colors.transparent,
                borderRadius: BorderRadius.circular(square ? 8 : 99),
                border: Border.all(
                  color: checked
                      ? AppColors.iconCream
                      : Colors.white.withValues(alpha: .22),
                  width: 2,
                ),
              ),
              child: checked
                  ? Icon(
                      Icons.check,
                      color: AppColors.deepEmerald,
                      size: square ? 22 : 20,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementChoice extends StatelessWidget {
  const _StatementChoice({
    required this.slide,
    required this.selected,
    required this.onSelected,
  });

  final OnboardingSlideData slide;
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 80),
        _QuoteCard(text: slide.statement ?? ''),
        const SizedBox(height: 120),
        Row(
          children: [
            for (final option in slide.options) ...[
              Expanded(
                child: _LargeChoice(
                  label: option,
                  icon: option.toLowerCase().startsWith('n')
                      ? Icons.close
                      : Icons.check,
                  checked: selected.contains(option),
                  onTap: () => onSelected(option),
                ),
              ),
              if (option != slide.options.last) const SizedBox(width: 18),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 26),
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.deepEmerald.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.iconCream,
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B211F),
              border: Border.all(
                color: Colors.white.withValues(alpha: .16),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.format_quote,
              color: AppColors.iconCream,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class _LargeChoice extends StatelessWidget {
  const _LargeChoice({
    required this.label,
    required this.icon,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 190,
        decoration: BoxDecoration(
          color: checked
              ? AppColors.deepEmerald.withValues(alpha: .5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: checked
                ? AppColors.iconCream.withValues(alpha: .48)
                : Colors.white.withValues(alpha: .18),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: checked
                  ? AppColors.iconCream
                  : Colors.white.withValues(alpha: .09),
              child: Icon(
                icon,
                color: checked ? AppColors.deepEmerald : AppColors.iconCream,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.iconCream,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.name, required this.text});

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.iconCream.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.iconCream,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              for (var i = 0; i < 5; i++)
                const Icon(Icons.star, color: AppColors.iconCream, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.iconCream,
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    final bars = [
      ('Spiritual\nGrowth', .92, AppColors.sproutGreen),
      ('Addiction\nHealing', .46, AppColors.leafGreen),
      ('Decision\nMaking', .60, AppColors.iconCream),
      ('Relationships', .74, AppColors.baseEarth),
    ];
    return Container(
      height: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.iconCream.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    bar.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.iconCream,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    heightFactor: 1,
                    child: Container(
                      height: 220 * bar.$2,
                      decoration: BoxDecoration(
                        color: bar.$3.withValues(alpha: .86),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (bar != bars.last) const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteIndex = (minute / 5).round().clamp(0, 11);
    final selectedMinute = minuteIndex * 5;

    int to24Hour(int displayHour, String selectedPeriod) {
      final base = displayHour % 12;
      return selectedPeriod == 'PM' ? base + 12 : base;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deepEmerald.withValues(alpha: .72),
                Colors.white.withValues(alpha: .05),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.iconCream.withValues(alpha: .16),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.schedule_outlined,
                color: AppColors.iconCream,
                size: 30,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your daily sacred pause',
                      style: TextStyle(
                        color: AppColors.iconCream,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Choose a realistic time when you can slow down. This sets apart a dependable moment for prayer, Scripture, and peace; it is not a deadline.',
                      style: TextStyle(
                        color: Color(0xBFF8F1E3),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.iconCream.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '${hour12.toString().padLeft(2, '0')} : ${selectedMinute.toString().padLeft(2, '0')} $period',
            style: const TextStyle(
              color: AppColors.iconCream,
              fontSize: 30,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 218,
          child: Row(
            children: [
              Expanded(
                child: _ReminderWheel<int>(
                  label: 'Hour',
                  values: List<int>.generate(12, (index) => index + 1),
                  selectedIndex: hour12 - 1,
                  format: (value) => value.toString().padLeft(2, '0'),
                  onSelected: (value) =>
                      onChanged(to24Hour(value, period), selectedMinute),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ReminderWheel<int>(
                  label: 'Minute',
                  values: List<int>.generate(12, (index) => index * 5),
                  selectedIndex: minuteIndex,
                  format: (value) => value.toString().padLeft(2, '0'),
                  onSelected: (value) => onChanged(hour, value),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ReminderWheel<String>(
                  label: 'Period',
                  values: const ['AM', 'PM'],
                  selectedIndex: period == 'AM' ? 0 : 1,
                  format: (value) => value,
                  onSelected: (value) =>
                      onChanged(to24Hour(hour12, value), selectedMinute),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Scroll each wheel. Your selected time stays centered and will be saved to your ReviveSpring account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.iconCream.withValues(alpha: .66),
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReminderWheel<T> extends StatefulWidget {
  const _ReminderWheel({
    required this.label,
    required this.values,
    required this.selectedIndex,
    required this.format,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final int selectedIndex;
  final String Function(T value) format;
  final ValueChanged<T> onSelected;

  @override
  State<_ReminderWheel<T>> createState() => _ReminderWheelState<T>();
}

class _ReminderWheelState<T> extends State<_ReminderWheel<T>> {
  late final FixedExtentScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant _ReminderWheel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        controller.hasClients &&
        controller.selectedItem != widget.selectedIndex) {
      controller.animateToItem(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            color: AppColors.iconCream.withValues(alpha: .66),
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .045),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .14),
                  ),
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.iconCream.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.iconCream.withValues(alpha: .3),
                    ),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 52,
                diameterRatio: 1.35,
                perspective: .004,
                physics: const FixedExtentScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                overAndUnderCenterOpacity: .32,
                onSelectedItemChanged: (index) {
                  HapticFeedback.selectionClick();
                  widget.onSelected(widget.values[index]);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, index) => Center(
                    child: Text(
                      widget.format(widget.values[index]),
                      style: const TextStyle(
                        color: AppColors.iconCream,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.slide});

  final OnboardingSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Illustration(icon: slide.icon, color: slide.color, index: 3),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                slide.body ?? '',
                style: const TextStyle(
                  color: AppColors.iconCream,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.check_circle_outline, color: AppColors.iconCream),
          ],
        ),
      ],
    );
  }
}

class _BuilderCard extends StatelessWidget {
  const _BuilderCard({
    required this.slide,
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final OnboardingSlideData slide;
  final int index;
  final Set<String> selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final builderStep = index - (onboardingSlides.length - 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < builderStep; i++) ...[
          _BuildProgress(label: i == 0 ? 'Goals' : 'Growth areas', done: true),
          const SizedBox(height: 18),
        ],
        _BuildProgress(label: slide.body ?? 'Personal path', done: false),
        const SizedBox(height: 34),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To move forward, specify',
                style: TextStyle(
                  color: AppColors.iconCream.withValues(alpha: .5),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                slide.statement ?? '',
                style: const TextStyle(
                  color: AppColors.iconCream,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  for (final option in slide.options) ...[
                    Expanded(
                      child: _BuilderButton(
                        label: option,
                        checked: selected.contains(option),
                        onTap: () => onSelected(option),
                      ),
                    ),
                    if (option != slide.options.last) const SizedBox(width: 18),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 220),
        const Center(
          child: Text(
            '#1 Christian platform\nfor spiritual growth',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.iconCream,
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildProgress extends StatelessWidget {
  const _BuildProgress({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.iconCream,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            done
                ? const Icon(Icons.check_circle, color: AppColors.iconCream)
                : const Text(
                    '49%',
                    style: TextStyle(
                      color: AppColors.iconCream,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: done ? 1 : .49,
            minHeight: 5,
            color: AppColors.iconCream,
            backgroundColor: Colors.white.withValues(alpha: .12),
          ),
        ),
      ],
    );
  }
}

class _BuilderButton extends StatelessWidget {
  const _BuilderButton({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: checked
            ? AppColors.iconCream
            : AppColors.iconCream.withValues(alpha: .12),
        foregroundColor: checked ? AppColors.deepEmerald : AppColors.iconCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _CommitCard extends StatefulWidget {
  const _CommitCard({required this.committed, required this.onCommitted});

  final bool committed;
  final ValueChanged<Offset?> onCommitted;

  @override
  State<_CommitCard> createState() => _CommitCardState();
}

class _CommitCardState extends State<_CommitCard> {
  Timer? _haptics;
  bool _holding = false;

  void _startHaptics() {
    if (_holding) return;
    _holding = true;
    HapticFeedback.mediumImpact();
    _haptics = Timer.periodic(const Duration(milliseconds: 85), (_) {
      HapticFeedback.selectionClick();
    });
    setState(() {});
  }

  void _stopHaptics() {
    _holding = false;
    _haptics?.cancel();
    _haptics = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _haptics?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final committed = widget.committed;
    return Column(
      children: [
        Text(
          "This isn't a big vow - it's a small yes to growing with God. Here's what you're saying yes to:\n\n"
          "- A few moments each day with God's Word.\n"
          "- A safe space to reflect and recharge.\n\n"
          'ReviveSpring is here to walk with you, not pressure you.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.iconCream,
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 72),
        Text(
          committed ? 'Committed' : 'Press and hold to commit',
          style: TextStyle(
            color: AppColors.iconCream.withValues(alpha: .55),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onLongPressStart: (_) => _startHaptics(),
          onLongPressCancel: _stopHaptics,
          onLongPressEnd: (details) {
            _stopHaptics();
            widget.onCommitted(details.globalPosition);
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            scale: _holding ? 1.06 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: committed ? AppColors.iconCream : AppColors.deepEmerald,
                boxShadow: [
                  BoxShadow(
                    color:
                        (committed
                                ? AppColors.iconCream
                                : AppColors.deepEmerald)
                            .withValues(alpha: _holding ? .5 : .28),
                    blurRadius: _holding ? 42 : 24,
                    spreadRadius: _holding ? 6 : 1,
                  ),
                ],
              ),
              child: Icon(
                committed ? Icons.check : Icons.touch_app_outlined,
                color: committed ? AppColors.deepEmerald : AppColors.iconCream,
                size: 50,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.icon,
    required this.color,
    required this.index,
  });

  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.iconCream.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: 24,
            child: _SoftCircle(size: 150, color: color),
          ),
          Positioned(
            right: -20,
            bottom: -28,
            child: _SoftCircle(size: 190, color: AppColors.iconCream),
          ),
          Center(
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: AppColors.iconCream,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, color: AppColors.deepEmerald, size: 58),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: .18),
      ),
    );
  }
}
