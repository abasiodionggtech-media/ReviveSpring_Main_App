import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/curved_nav_bar.dart';
import '../../widgets/premium_upgrade_sheet.dart';
import 'ai_screen.dart';
import 'bible_screen.dart';
import 'customer_care_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'notifications_screen.dart';
import 'prayer_library_screen.dart';
import 'profile_screen.dart';
import 'wellness_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int tab = 0;
  final List<int> tabHistory = [];
  Timer? _pollTimer;
  Offset _premiumCardOffset = Offset.zero;
  bool _premiumCardDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      widget.controller.refreshSupportTickets();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.consumePendingSupportTicketId() != null) {
        selectTab(7);
      }
      widget.controller.refreshSupportTickets();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshSupportTickets();
    }
  }

  void selectTab(int value) {
    if (value == tab) return;
    tabHistory.add(tab);
    setState(() => tab = value);
  }

  bool handleBack() {
    if (tabHistory.isNotEmpty) {
      setState(() => tab = tabHistory.removeLast());
      return true;
    }
    if (tab != 0) {
      setState(() => tab = 0);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        controller: widget.controller,
        onOpenAi: () => selectTab(5),
        onOpenPrayers: () => selectTab(1),
      ),
      PrayerLibraryScreen(
        controller: widget.controller,
        onOpenAi: () => selectTab(5),
      ),
      JournalScreen(controller: widget.controller),
      GoalsScreen(controller: widget.controller),
      WellnessScreen(controller: widget.controller, onNavigate: selectTab),
      BibleScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
      CustomerCareScreen(controller: widget.controller, onBack: handleBack),
      NotificationsScreen(controller: widget.controller, onBack: handleBack),
    ];

    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: screens[tab],
              ),
              if (widget.controller.shouldShowUpgradeCard &&
                  tab == 0 &&
                  !_premiumCardDismissed)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 150,
                  child: Transform.translate(
                    offset: _premiumCardOffset,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _premiumCardOffset += details.delta;
                        });
                      },
                      onPanEnd: (_) {
                        if (_premiumCardOffset.dx.abs() > 120 ||
                            _premiumCardOffset.dy.abs() > 90) {
                          setState(() => _premiumCardDismissed = true);
                        }
                      },
                      onTap: () =>
                          PremiumUpgradeSheet.show(context, widget.controller),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.iconCream.withValues(alpha: .97),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppColors.deepEmerald.withValues(
                                  alpha: .12,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepEmerald.withValues(
                                    alpha: .10,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.leaf.withValues(
                                          alpha: .16,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_outlined,
                                        color: AppColors.deepEmerald,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget
                                                .controller
                                                .premiumBannerTitle,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.deepEmerald,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.controller.premiumBannerBody,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(
                                        () => _premiumCardDismissed = true,
                                      ),
                                      icon: const Icon(Icons.close),
                                      color: AppColors.deepEmerald,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget
                                            .controller
                                            .subscriptionPriceLabel,
                                        style: const TextStyle(
                                          color: AppColors.deepEmerald,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () => PremiumUpgradeSheet.show(
                                        context,
                                        widget.controller,
                                      ),
                                      icon: const Icon(Icons.arrow_upward),
                                      label: Text(
                                        widget.controller.premiumBannerCta,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                right: 18,
                child: Row(
                  children: [
                    _HeaderActionButton(
                      icon: Icons.notifications_active_outlined,
                      badge: widget.controller.unreadAlertCount,
                      onTap: () => selectTab(8),
                    ),
                    const SizedBox(width: 8),
                    _HeaderActionButton(
                      icon: Icons.support_agent,
                      onTap: () => selectTab(7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // AI has left the navigation (Bible took its place) — it now lives as a
        // floating button above the bar, so it's still one tap away.
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: _AiFab(controller: widget.controller),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: CurvedNavBar(
            currentIndex: tab > 6 ? 6 : tab,
            onTap: selectTab,
            items: const [
              CurvedNavItem(icon: Icons.home_rounded, label: 'Home'),
              CurvedNavItem(icon: Icons.volunteer_activism_rounded, label: 'Pray'),
              CurvedNavItem(icon: Icons.edit_note_rounded, label: 'Journal'),
              CurvedNavItem(icon: Icons.flag_rounded, label: 'Goals'),
              CurvedNavItem(icon: Icons.spa_rounded, label: 'Wellness'),
              // AI has left the nav — Bible takes its place. AI is now the
              // floating button above the bar.
              CurvedNavItem(icon: Icons.menu_book_rounded, label: 'Bible'),
              CurvedNavItem(icon: Icons.person_rounded, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      shadowColor: AppColors.deepEmerald.withValues(alpha: .16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.deepEmerald.withValues(alpha: .1),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, color: AppColors.deepEmerald)),
              if (badge > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
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


/// The AI companion, lifted out of the navigation bar.
class _AiFab extends StatelessWidget {
  const _AiFab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                backgroundColor: AppColors.panel,
                appBar: AppBar(
                  backgroundColor: AppColors.panel,
                  elevation: 0,
                  title: const Text('AI Companion'),
                ),
                body: AiScreen(controller: controller),
              ),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E6B5B), AppColors.deepEmerald, Color(0xFF08322A)],
                stops: [0, .55, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepEmerald.withValues(alpha: .6),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
