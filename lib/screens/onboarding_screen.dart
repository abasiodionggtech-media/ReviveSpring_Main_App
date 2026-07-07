import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_controller.dart';
import '../core/app_stage.dart';
import '../data/app_data.dart';
import '../widgets/app_buttons.dart';
import '../widgets/premium_upgrade_sheet.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

String? _firstOrNull(List? list) {
  if (list == null || list.isEmpty) return null;
  return list.first.toString();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Map<String, dynamic> answers = {};
  int reminderHour = 9;
  int reminderMinute = 0;
  bool useDifferentEmail = false;
  bool submitting = false;
  late final TextEditingController nameController;
  late final TextEditingController emailController;

  AppController get controller => widget.controller;
  OnboardingStep get step => onboardingSteps[controller.onboardingIndex];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: controller.user?.fullName ?? '');
    emailController = TextEditingController(text: controller.user?.email ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  bool get canContinue {
    if (step.optional) return true;
    switch (step.type) {
      case OnboardingStepType.singleChoice:
        return answers[step.id] != null;
      case OnboardingStepType.multiChoice:
        return ((answers[step.id] as List?)?.isNotEmpty ?? false);
      case OnboardingStepType.profileSetup:
        return nameController.text.trim().isNotEmpty;
      case OnboardingStepType.tour:
      case OnboardingStepType.reminder:
      case OnboardingStepType.emailConfirm:
      case OnboardingStepType.premium:
      case OnboardingStepType.summary:
        return true;
    }
  }

  void selectSingle(String label) {
    HapticFeedback.selectionClick();
    setState(() => answers[step.id] = label);
  }

  void toggleMulti(OnboardingOption option) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = List<String>.from(answers[step.id] as List? ?? const []);
      if (option.exclusive) {
        current
          ..clear()
          ..add(option.label);
      } else {
        // Selecting a non-exclusive option always clears any exclusive pick.
        for (final other in step.options) {
          if (other.exclusive) current.remove(other.label);
        }
        if (current.contains(option.label)) {
          current.remove(option.label);
        } else {
          final max = step.maxSelect;
          if (max != null && current.length >= max) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can choose up to $max.'),
                backgroundColor: AppColors.deepEmerald,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          current.add(option.label);
        }
      }
      answers[step.id] = current;
    });
  }

  Future<void> continueFlow() async {
    if (!canContinue || submitting) return;
    if (step.type == OnboardingStepType.summary) {
      await _finish();
    } else {
      controller.nextOnboarding();
    }
  }

  Future<void> _finish() async {
    setState(() => submitting = true);
    final newName = nameController.text.trim();
    if (newName.isNotEmpty && newName != controller.user?.fullName) {
      await controller.updateFullName(newName);
    }

    final pref = answers['notificationPreference'] as String?;
    bool wantsPush = false;
    bool wantsEmail = true;
    switch (pref) {
      case 'Push notifications on my phone':
        wantsPush = true;
        wantsEmail = false;
        break;
      case 'Daily prayer email':
        wantsPush = false;
        wantsEmail = true;
        break;
      case 'Both push and email':
        wantsPush = true;
        wantsEmail = true;
        break;
      case "Neither — I'll open the app myself":
        wantsPush = false;
        wantsEmail = false;
        break;
    }

    await controller.saveOnboarding({
      ...answers,
      'preferredContactEmail': useDifferentEmail ? emailController.text.trim() : controller.user?.email,
      'reminderTime': {
        'hour': reminderHour,
        'minute': reminderMinute,
        'timezone': DateTime.now().timeZoneName,
        'dailyEmailEnabled': wantsEmail,
        'pushNotificationsEnabled': wantsPush,
      },
    });
    if (!mounted) return;
    controller.go(AppStage.app);
  }

  String get _primaryLabel {
    switch (step.type) {
      case OnboardingStepType.tour:
        return 'Get Started';
      case OnboardingStepType.premium:
        return 'Continue with Free';
      case OnboardingStepType.summary:
        return 'Begin My Prayer Journey';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = controller.onboardingIndex;
    return Scaffold(
      backgroundColor: const Color(0xFF121715),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
          child: Column(
            children: [
              _OnboardingHeader(
                index: index,
                total: onboardingSteps.length,
                section: step.section,
                onBack: index == 0 ? null : controller.previousOnboarding,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(index),
                    physics: const BouncingScrollPhysics(),
                    child: _buildBody(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedPrimaryButton(
                label: _primaryLabel,
                icon: Icons.arrow_forward,
                busy: submitting,
                onPressed: canContinue && !submitting ? continueFlow : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (step.type) {
      case OnboardingStepType.tour:
        return _TourCarousel(step: step);
      case OnboardingStepType.singleChoice:
        return _ChoiceList(
          step: step,
          selected: {if (answers[step.id] != null) answers[step.id] as String},
          onTap: (option) => selectSingle(option.label),
          onSkip: step.optional ? continueFlow : null,
        );
      case OnboardingStepType.multiChoice:
        return _ChoiceList(
          step: step,
          selected: Set<String>.from(answers[step.id] as List? ?? const []),
          onTap: toggleMulti,
        );
      case OnboardingStepType.reminder:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepTitle(step: step),
            const SizedBox(height: 22),
            _ReminderCard(
              hour: reminderHour,
              minute: reminderMinute,
              onChanged: (hour, minute) => setState(() {
                reminderHour = hour;
                reminderMinute = minute;
              }),
            ),
          ],
        );
      case OnboardingStepType.emailConfirm:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepTitle(step: step),
            const SizedBox(height: 22),
            _EmailConfirmCard(
              email: controller.user?.email ?? '',
              useDifferentEmail: useDifferentEmail,
              emailController: emailController,
              onToggle: (value) => setState(() => useDifferentEmail = value),
            ),
          ],
        );
      case OnboardingStepType.profileSetup:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepTitle(step: step),
            const SizedBox(height: 22),
            _ProfileSetupCard(
              nameController: nameController,
              photoUrl: controller.user?.photoUrl,
              onChanged: () => setState(() {}),
            ),
          ],
        );
      case OnboardingStepType.premium:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepTitle(step: step),
            const SizedBox(height: 22),
            _PremiumCard(onUpgrade: () => PremiumUpgradeSheet.show(context, controller)),
          ],
        );
      case OnboardingStepType.summary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepTitle(step: step),
            const SizedBox(height: 22),
            _SummaryCard(
              name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : (controller.user?.fullName ?? 'Friend'),
              language: controller.language,
              topFocus: _firstOrNull(answers['spiritualGoals'] as List?) ?? _firstOrNull(answers['prayerFocus'] as List?),
              reminderHour: reminderHour,
              reminderMinute: reminderMinute,
            ),
          ],
        );
    }
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.index,
    required this.total,
    required this.section,
    required this.onBack,
  });

  final int index;
  final int total;
  final String section;
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
              Text(
                section,
                style: const TextStyle(
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
                  color: AppColors.sproutGreen,
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

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.title,
          style: const TextStyle(
            color: AppColors.iconCream,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        if (step.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            step.subtitle!,
            style: TextStyle(
              color: AppColors.iconCream.withValues(alpha: .68),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({required this.step, required this.selected, required this.onTap, this.onSkip});

  final OnboardingStep step;
  final Set<String> selected;
  final ValueChanged<OnboardingOption> onTap;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(step: step),
        const SizedBox(height: 22),
        ...step.options.map((option) {
          final isSelected = selected.contains(option.label);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionTile(option: option, selected: isSelected, onTap: () => onTap(option)),
          );
        }),
        if (onSkip != null)
          Center(
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                'Skip this step',
                style: TextStyle(color: AppColors.iconCream.withValues(alpha: .6), fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, required this.selected, required this.onTap});

  final OnboardingOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.leafGreen : Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? AppColors.sproutGreen : Colors.white.withValues(alpha: .12)),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.leafGreen.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.label,
                    style: const TextStyle(color: AppColors.iconCream, fontWeight: FontWeight.w700, height: 1.3, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: selected ? 1 : 0,
                  child: const Icon(Icons.check_circle, color: AppColors.iconCream, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TourCarousel extends StatefulWidget {
  const _TourCarousel({required this.step});

  final OnboardingStep step;

  @override
  State<_TourCarousel> createState() => _TourCarouselState();
}

class _TourCarouselState extends State<_TourCarousel> {
  final controller = PageController();
  int page = 0;

  static const _blurbs = [
    'Guided daily prayers for every season of life.',
    'Capture your thoughts and celebrate answered prayers.',
    'Small, honest steps that build a lasting habit.',
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(step: widget.step),
        const SizedBox(height: 24),
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: controller,
            itemCount: widget.step.options.length,
            onPageChanged: (value) => setState(() => page = value),
            itemBuilder: (context, index) {
              final option = widget.step.options[index];
              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: page == index ? 0 : 14, horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.deepEmerald.withValues(alpha: .8), Colors.white.withValues(alpha: .05)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withValues(alpha: .14)),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(option.emoji, style: const TextStyle(fontSize: 46)),
                      const SizedBox(height: 18),
                      Text(
                        option.label,
                        style: const TextStyle(color: AppColors.iconCream, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _blurbs[index % _blurbs.length],
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.iconCream.withValues(alpha: .74), height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.step.options.length, (index) {
            final active = index == page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.sproutGreen : Colors.white.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Swipe to preview',
            style: TextStyle(color: AppColors.iconCream.withValues(alpha: .5), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _EmailConfirmCard extends StatelessWidget {
  const _EmailConfirmCard({
    required this.email,
    required this.useDifferentEmail,
    required this.emailController,
    required this.onToggle,
  });

  final String email;
  final bool useDifferentEmail;
  final TextEditingController emailController;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail_outline, color: AppColors.iconCream),
              const SizedBox(width: 12),
              Expanded(
                child: Text(email, style: const TextStyle(color: AppColors.iconCream, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _PillChoice(label: 'This is correct ✓', selected: !useDifferentEmail, onTap: () => onToggle(false)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PillChoice(label: 'Update email', selected: useDifferentEmail, onTap: () => onToggle(true)),
            ),
          ],
        ),
        if (useDifferentEmail) ...[
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.iconCream),
            decoration: InputDecoration(
              hintText: 'name@example.com',
              hintStyle: TextStyle(color: AppColors.iconCream.withValues(alpha: .4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This sets where your daily devotional is sent. To change your account login email, use Settings later.',
            style: TextStyle(color: AppColors.iconCream.withValues(alpha: .55), fontSize: 12, height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _PillChoice extends StatelessWidget {
  const _PillChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.leafGreen : Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.iconCream, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _ProfileSetupCard extends StatelessWidget {
  const _ProfileSetupCard({required this.nameController, required this.photoUrl, required this.onChanged});

  final TextEditingController nameController;
  final String? photoUrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploads are coming soon.'), backgroundColor: AppColors.deepEmerald),
          ),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: Colors.white.withValues(alpha: .08),
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(Icons.person_outline, color: AppColors.iconCream, size: 40)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.leafGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.iconCream, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Photo optional', style: TextStyle(color: AppColors.iconCream.withValues(alpha: .5), fontSize: 12)),
        const SizedBox(height: 22),
        TextField(
          controller: nameController,
          onChanged: (_) => onChanged(),
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.iconCream, fontSize: 16, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: 'First name',
            labelStyle: TextStyle(color: AppColors.iconCream.withValues(alpha: .6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: .06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onUpgrade});

  final VoidCallback onUpgrade;

  static const _highlights = [
    ('💬', 'Unlimited AI Prayer Companion chat'),
    ('🧘', 'Full Mental Wellness content library'),
    ('🚫', 'No ads, ever'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepEmerald, Colors.white.withValues(alpha: .05)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in _highlights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(item.$1, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.$2, style: const TextStyle(color: AppColors.iconCream, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              AnimatedPrimaryButton(label: 'Upgrade to Premium', icon: Icons.workspace_premium_outlined, onPressed: onUpgrade),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.name,
    required this.language,
    required this.topFocus,
    required this.reminderHour,
    required this.reminderMinute,
  });

  final String name;
  final String language;
  final String? topFocus;
  final int reminderHour;
  final int reminderMinute;

  @override
  Widget build(BuildContext context) {
    final hour12 = reminderHour % 12 == 0 ? 12 : reminderHour % 12;
    final period = reminderHour >= 12 ? 'PM' : 'AM';
    final time = '${hour12.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')} $period';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "You're ready, $name! 🎉",
          style: const TextStyle(color: AppColors.iconCream, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
          ),
          child: Column(
            children: [
              _SummaryRow(icon: Icons.language, label: 'Language', value: language.toUpperCase()),
              if (topFocus != null) _SummaryRow(icon: Icons.favorite_outline, label: 'Top focus', value: topFocus!),
              _SummaryRow(icon: Icons.schedule_outlined, label: 'Daily reminder', value: time),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Everything is set. Tap below whenever you are ready to begin.',
          style: TextStyle(color: AppColors.iconCream.withValues(alpha: .65), height: 1.4),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.sproutGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: AppColors.iconCream.withValues(alpha: .7), fontWeight: FontWeight.w700))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.iconCream, fontWeight: FontWeight.w900),
            ),
          ),
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
