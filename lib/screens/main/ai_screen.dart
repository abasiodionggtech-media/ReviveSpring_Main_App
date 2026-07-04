import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/mobile_ads_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/premium_upgrade_sheet.dart';
import '../../widgets/section_header.dart';

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
    String? unlockToken;
    if (!widget.controller.isPremiumUser) {
      final approved = await _showAiAdGate();
      if (!approved) return;
      final rewarded = await MobileAdsService.instance.showRewardedAiUnlockAd();
      if (!rewarded) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(
                'The ad was not completed, so AI access was not unlocked yet.',
                'La pub n a pas ete terminee, donc l acces IA n a pas encore ete debloque.',
              ),
            ),
          ),
        );
        return;
      }
      try {
        final unlock = await widget.controller.unlockAiForFreeUser();
        unlockToken = (unlock['unlockToken'] ?? '').toString();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(
                'Daily AI limit reached or AI access is unavailable right now.',
                'La limite quotidienne de l IA est atteinte ou l acces est indisponible pour le moment.',
              ),
            ),
          ),
        );
        return;
      }
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
      unlockToken: unlockToken,
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

  Future<bool> _showAiAdGate() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _AiRewardDialog(
            title: t(
              'Watch this short ad to use AI',
              'Regardez cette courte pub pour utiliser l IA',
            ),
            body: t(
              'Free users can unlock one AI use by viewing this short sponsor message. You can do this up to 5 times per day.',
              'Les utilisateurs gratuits peuvent debloquer une utilisation de l IA en regardant ce court message sponsorise. Vous pouvez le faire jusqu a 5 fois par jour.',
            ),
            actionLabel: t('Watch ad now', 'Regarder la pub maintenant'),
            cancelLabel: t('Cancel', 'Annuler'),
            sponsorCopy: t(
              'ReviveSpring Premium\nNo ads. Unlimited AI. Full access.',
              'ReviveSpring Premium\nSans pubs. IA illimitee. Acces complet.',
            ),
            countdownLabel: (seconds) => t(
              'Starting in ${seconds}s...',
              'Demarrage dans ${seconds}s...',
            ),
          ),
        ) ??
        false;
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
        if (!widget.controller.isPremiumUser)
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Free AI access', 'Acces IA gratuit'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t(
                    'Watch one short ad before each AI use. Daily limit: 5.',
                    'Regardez une courte pub avant chaque utilisation de l IA. Limite quotidienne : 5.',
                  ),
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 10),
                Text(
                  t(
                    'Remaining today: ${widget.controller.aiDailyRemaining}',
                    'Restant aujourd hui : ${widget.controller.aiDailyRemaining}',
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

class _AiRewardDialog extends StatefulWidget {
  const _AiRewardDialog({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.cancelLabel,
    required this.sponsorCopy,
    required this.countdownLabel,
  });

  final String title;
  final String body;
  final String actionLabel;
  final String cancelLabel;
  final String sponsorCopy;
  final String Function(int seconds) countdownLabel;

  @override
  State<_AiRewardDialog> createState() => _AiRewardDialogState();
}

class _AiRewardDialogState extends State<_AiRewardDialog> {
  int secondsLeft = 5;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      if (!mounted || secondsLeft <= 0) return false;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => secondsLeft -= 1);
      return secondsLeft > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = secondsLeft <= 0;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.body),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.deepEmerald.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.sponsorCopy,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ready ? widget.actionLabel : widget.countdownLabel(secondsLeft),
            style: const TextStyle(
              color: AppColors.deepEmerald,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: ready ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
