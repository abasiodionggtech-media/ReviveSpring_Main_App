import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/premium_upgrade_sheet.dart';
import '../../widgets/section_header.dart';
import 'ai_companion_screen.dart';
import 'ai_prayer_writer_screen.dart';
import 'dream_journal_screen.dart';
import 'scripture_search_screen.dart';
import 'sermon_summarizer_screen.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final input = TextEditingController();
  final ai = AiService();
  final messages = <ChatMessage>[];
  final initialMessage = const ChatMessage(
    role: 'model',
    content:
        'Hello. I am your Bible and prayer AI. Ask me for a prayer, verse, or encouragement.',
  );
  List<Map<String, dynamic>> sessions = const [];
  String sessionId = '';
  bool typing = false;
  bool loadingHistory = false;

  String get userEmail =>
      (widget.controller.user?.email ?? '').trim().toLowerCase();
  String t(String en, String fr) =>
      AppStrings.of(widget.controller.language, en, fr);

  @override
  void initState() {
    super.initState();
    sessionId = userEmail.isNotEmpty
        ? ai.defaultSessionForEmail(userEmail)
        : 'rs-user-anon';
    messages.add(initialMessage);
    _loadHistory(sessionId);
    _loadSessions();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send([String? suggestion]) async {
    final text = (suggestion ?? input.text).trim();
    if (text.isEmpty || typing) return;

    // Ads are gone. Access is now purely plan-based:
    //   Premium  → unlimited
    //   Standard → 20 messages a month (no rollover; the backend counts them)
    //   anyone else (trial expired / free) → upgrade prompt
    if (!widget.controller.isPremiumUser && !widget.controller.isStandardUser) {
      if (!mounted) return;
      await _showUpgradeSheet();
      return;
    }

    setState(() {
      input.clear();
      typing = true;
      messages.add(ChatMessage(role: 'user', content: text));
    });
    final reply = await ai.sendMessage(
      message: text,
      language: widget.controller.language,
      sessionId: sessionId,
      userEmail: widget.controller.user?.email,
      authToken: widget.controller.api.token,
      unlockToken: null,
      history: messages,
    );
    if (!mounted) return;
    setState(() {
      typing = false;
      messages.add(ChatMessage(role: 'model', content: reply));
    });
    await _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (userEmail.isEmpty) return;
    final list = await ai.getSessions(
      userEmail: userEmail,
      authToken: widget.controller.api.token,
    );
    if (!mounted) return;
    setState(() => sessions = list);
  }

  Future<void> _loadHistory(String nextSessionId) async {
    if (userEmail.isEmpty) return;
    setState(() {
      loadingHistory = true;
      sessionId = nextSessionId;
    });
    final history = await ai.getHistory(
      sessionId: nextSessionId,
      userEmail: userEmail,
      authToken: widget.controller.api.token,
    );
    if (!mounted) return;
    setState(() {
      loadingHistory = false;
      messages
        ..clear()
        ..addAll(history.isEmpty ? [initialMessage] : history);
    });
  }

  void _newConversation() {
    final nextSession =
        '${ai.defaultSessionForEmail(userEmail)}-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      sessionId = nextSession;
      messages
        ..clear()
        ..add(initialMessage);
      input.clear();
    });
  }

  /// Shown when someone with no AI entitlement tries to send a message.
  /// (Ads are gone — the only route to AI is a subscription.)
  Future<void> _showUpgradeSheet() async {
    // PremiumUpgradeSheet exposes a static show() — it isn't a widget.
    await PremiumUpgradeSheet.show(context, widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      t(
        'Give me a prayer for anxiety',
        'Donne-moi une priere contre l anxiete',
      ),
      t('Bible verse for strength', 'Verset biblique pour la force'),
      t('Prayer for healing', 'Priere pour la guerison'),
      t('How can I strengthen my faith?', 'Comment puis-je fortifier ma foi ?'),
    ];
    return ListView(
      key: const ValueKey('ai'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        SectionHeader(
          title: t('AI Prayer Companion', 'Assistant de priere IA'),
          subtitle: t(
            'Signed-in guidance for prayer and reflection.',
            'Un accompagnement connecte pour la priere et la reflexion.',
          ),
          icon: Icons.auto_awesome,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ScriptureSearchScreen(controller: widget.controller),
                  ),
                ),
                icon: const Icon(Icons.search),
                label: Text(
                  t('Topical Scripture Search', 'Recherche de versets'),
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (!widget.controller.isPremiumUser) {
                    PremiumUpgradeSheet.show(context, widget.controller);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AiPrayerWriterScreen(controller: widget.controller),
                    ),
                  );
                },
                icon: Icon(widget.controller.isPremiumUser ? Icons.edit_note : Icons.lock_outline),
                label: Text(
                  t('AI Prayer Writer', 'Redacteur de prieres IA'),
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PremiumFeatureButton(
              label: t('Spiritual Companion', 'Compagnon spirituel'),
              icon: Icons.favorite_border,
              isPremium: widget.controller.isPremiumUser,
              onPressed: () {
                if (!widget.controller.isPremiumUser) {
                  PremiumUpgradeSheet.show(context, widget.controller);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => AiCompanionScreen(controller: widget.controller)),
                );
              },
            ),
            _PremiumFeatureButton(
              label: t('Sermon Summarizer', 'Resume de sermon'),
              icon: Icons.summarize_outlined,
              isPremium: widget.controller.isPremiumUser,
              onPressed: () {
                if (!widget.controller.isPremiumUser) {
                  PremiumUpgradeSheet.show(context, widget.controller);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => SermonSummarizerScreen(controller: widget.controller)),
                );
              },
            ),
            _PremiumFeatureButton(
              label: t('Dream & Vision Journal', 'Journal de reves'),
              icon: Icons.nights_stay_outlined,
              isPremium: widget.controller.isPremiumUser,
              onPressed: () {
                if (!widget.controller.isPremiumUser) {
                  PremiumUpgradeSheet.show(context, widget.controller);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => DreamJournalScreen(controller: widget.controller)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (!widget.controller.isPremiumUser)
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('AI messages this month', 'Messages IA ce mois-ci'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t(
                    'Standard includes ${widget.controller.aiMonthlyAllowance} AI messages each month. Unused messages don\u2019t roll over.',
                    'Standard inclut ${widget.controller.aiMonthlyAllowance} messages IA par mois. Les messages non utilises ne sont pas reportes.',
                  ),
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 10),
                Text(
                  t(
                    '${widget.controller.aiRemainingThisMonth ?? 0} remaining',
                    '${widget.controller.aiRemainingThisMonth ?? 0} restants',
                  ),
                  style: const TextStyle(
                    color: AppColors.deepEmerald,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      PremiumUpgradeSheet.show(context, widget.controller),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: Text(t('Upgrade to premium', 'Passer premium')),
                ),
              ],
            ),
          ),
        if (!widget.controller.isPremiumUser) const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: suggestions
              .map(
                (item) =>
                    ActionChip(label: Text(item), onPressed: () => send(item)),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _newConversation,
              child: Text(t('New conversation', 'Nouvelle conversation')),
            ),
            ...sessions.take(5).map((item) {
              final id = (item['sessionId'] ?? '').toString();
              final active = id == sessionId;
              final preview =
                  (item['preview'] ?? t('Conversation', 'Conversation'))
                      .toString();
              return ChoiceChip(
                selected: active,
                onSelected: (_) => _loadHistory(id),
                label: Text(
                  preview.length > 24
                      ? '${preview.substring(0, 24)}...'
                      : preview,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        GlassPanel(
          child: Column(
            children: [
              if (loadingHistory)
                const LinearProgressIndicator(color: AppColors.deepEmerald),
              ...messages.map(
                (message) => Align(
                  alignment: message.role == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 310),
                    decoration: BoxDecoration(
                      color: message.role == 'user'
                          ? AppColors.deepEmerald
                          : AppColors.iconCream.withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: message.role == 'user'
                            ? AppColors.iconCream
                            : AppColors.deepEmerald,
                        height: 1.55,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (typing)
                const LinearProgressIndicator(color: AppColors.deepEmerald),
              const SizedBox(height: 12),
              AppTextField(
                label: t(
                  'Ask about Bible or prayer',
                  'Posez une question sur la Bible ou la priere',
                ),
                icon: Icons.chat_outlined,
                controller: input,
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AnimatedPrimaryButton(
                      label: t('Send', 'Envoyer'),
                      icon: Icons.send,
                      busy: typing,
                      onPressed: send,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingIconButton(
                    icon: Icons.bookmark_add_outlined,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// A feature tile on the AI screen. Locked features show a "Premium" badge and
/// route to the upgrade sheet instead of the feature.
class _PremiumFeatureButton extends StatelessWidget {
  const _PremiumFeatureButton({
    required this.label,
    required this.icon,
    required this.isPremium,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isPremium;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFEDF4F1)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .9)),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepEmerald.withValues(alpha: .22),
              blurRadius: 12,
              spreadRadius: -6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.deepEmerald),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.deepEmerald,
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                    color: AppColors.coral,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
