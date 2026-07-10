import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/realistic_flip_card.dart';
import '../../widgets/state_placeholders.dart';

class MemoryCardsScreen extends StatefulWidget {
  const MemoryCardsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;
  bool _hasError = false;
  String? _busyId;
  String? _expandedCardId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _cards.isEmpty;
      _hasError = false;
    });
    try {
      final cards = await widget.controller.api.getMemoryCards();
      if (mounted) setState(() => _cards = cards);
      await _checkDueCards();
    } catch (_) {
      if (mounted && _cards.isEmpty) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkDueCards() async {
    try {
      final due = await widget.controller.api.getDueMemoryCards();
      if (due.isNotEmpty && mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => _RecallReviewScreen(controller: widget.controller, card: due.first),
          ),
        );
        if (result == true) await _load();
      }
    } catch (_) {}
  }

  Future<void> _updateCard(String id, Future<Map<String, dynamic>> Function() action) async {
    setState(() => _busyId = id);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        final index = _cards.indexWhere((c) => c['id'] == id);
        if (index != -1) _cards[index] = updated;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Scripture Memory Cards')),
      body: _loading
          ? ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 40), children: const [SkeletonList(count: 4, itemHeight: 100)])
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.deepEmerald,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                children: [
                  const Text(
                    'Add a verse, flip the flashcard to review it, then in 7 days write it from memory to master it.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (_hasError)
                    ErrorState(message: "Couldn't load your memory cards right now.", onRetry: _load)
                  else
                    ..._cards.map((card) {
                      final added = card['added'] == true;
                      final mastered = card['mastered'] == true;
                      final quizUnlocked = card['quiz_unlocked'] == true;
                      final daysUntilQuiz = card['days_until_quiz'] as int?;
                      final busy = _busyId == card['id'];
                      final expanded = _expandedCardId == card['id'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: added
                            ? _AddedCard(
                                card: card,
                                busy: busy,
                                expanded: expanded,
                                mastered: mastered,
                                quizUnlocked: quizUnlocked,
                                daysUntilQuiz: daysUntilQuiz,
                                onToggleExpand: () => setState(() => _expandedCardId = expanded ? null : card['id'].toString()),
                                onReview: () => _updateCard(card['id'].toString(), () => widget.controller.api.reviewMemoryCard(card['id'].toString())),
                                onOpenRecall: quizUnlocked
                                    ? () async {
                                        final result = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute<bool>(builder: (_) => _RecallReviewScreen(controller: widget.controller, card: card)),
                                        );
                                        if (result == true) await _load();
                                      }
                                    : null,
                              )
                            : GlassPanel(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(card['reference']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                                          const SizedBox(height: 4),
                                          Text(
                                            card['verse']?.toString() ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      onPressed: busy ? null : () => _updateCard(card['id'].toString(), () => widget.controller.api.addMemoryCard(card['id'].toString())),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _AddedCard extends StatelessWidget {
  const _AddedCard({
    required this.card,
    required this.busy,
    required this.expanded,
    required this.mastered,
    required this.quizUnlocked,
    required this.daysUntilQuiz,
    required this.onToggleExpand,
    required this.onReview,
    required this.onOpenRecall,
  });

  final Map<String, dynamic> card;
  final bool busy;
  final bool expanded;
  final bool mastered;
  final bool quizUnlocked;
  final int? daysUntilQuiz;
  final VoidCallback onToggleExpand;
  final VoidCallback onReview;
  final VoidCallback? onOpenRecall;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleExpand,
            child: Row(
              children: [
                Expanded(child: Text(card['reference']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                if (mastered)
                  const Icon(Icons.verified, color: AppColors.leaf)
                else if (daysUntilQuiz != null && daysUntilQuiz! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
                    child: Text('Recall in ${daysUntilQuiz}d', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.deepEmerald)),
                  ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.expand_more, color: AppColors.muted),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _ExpandedCardBody(card: card, busy: busy, onReview: onReview, onOpenRecall: onOpenRecall),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ExpandedCardBody extends StatefulWidget {
  const _ExpandedCardBody({required this.card, required this.busy, required this.onReview, required this.onOpenRecall});

  final Map<String, dynamic> card;
  final bool busy;
  final VoidCallback onReview;
  final VoidCallback? onOpenRecall;

  @override
  State<_ExpandedCardBody> createState() => _ExpandedCardBodyState();
}

class _ExpandedCardBodyState extends State<_ExpandedCardBody> {
  final _flipKey = GlobalKey<RealisticFlipCardState>();

  Future<void> _share({required bool front, required bool back}) async {
    await _flipKey.currentState?.captureAndShare(includeFront: front, includeBack: back);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Column(
      children: [
        RealisticFlipCard(
          key: _flipKey,
          height: 190,
          front: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.deepEmerald, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book, color: Colors.white70, size: 26),
                const SizedBox(height: 10),
                Text(
                  card['reference']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text('Tap to reveal the verse', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          back: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.leafGreen.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"${card['verse'] ?? ''}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(card['reference']?.toString() ?? '', style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.busy ? null : widget.onReview,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(card['reviewed_today'] == true ? 'Reviewed today' : 'Mark Reviewed'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showShareSheet(context),
              icon: const Icon(Icons.ios_share, color: AppColors.deepEmerald),
              tooltip: 'Share as image',
            ),
          ],
        ),
        if (widget.onOpenRecall != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onOpenRecall,
              icon: const Icon(Icons.edit_note),
              label: const Text('Recall From Memory'),
            ),
          ),
        ],
      ],
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_square),
              title: const Text('Share front only'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _share(front: true, back: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square_outlined),
              title: const Text('Share back only'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _share(front: false, back: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_none),
              title: const Text('Share both'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _share(front: true, back: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen 7-day recall check: the user writes the verse from memory,
/// gets a real similarity-based pass/fail with a colored glow, sees the
/// actual verse either way, and is offered the next card in the queue.
class _RecallReviewScreen extends StatefulWidget {
  const _RecallReviewScreen({required this.controller, required this.card});

  final AppController controller;
  final Map<String, dynamic> card;

  @override
  State<_RecallReviewScreen> createState() => _RecallReviewScreenState();
}

class _RecallReviewScreenState extends State<_RecallReviewScreen> {
  final _textController = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.controller.api.recallMemoryCard(widget.card['id'].toString(), text);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't check your recall right now. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addNextCard(String id) async {
    try {
      await widget.controller.api.addMemoryCard(id);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final passed = result?['passed'] == true;
    final resultCard = result?['card'] as Map<String, dynamic>?;
    final nextSuggested = result?['next_suggested_card'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        elevation: 0,
        title: const Text('7-Day Recall Check'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          Text(
            widget.card['reference']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 6),
          const Text(
            "It's been 7 days. Without peeking, write out as much of this verse as you remember.",
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (result == null) ...[
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type the verse from memory...',
                filled: true,
                fillColor: AppColors.iconCream.withValues(alpha: .6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Checking...' : 'Check My Recall'),
              ),
            ),
          ] else ...[
            RealisticFlipCard(
              height: 200,
              startFlipped: true,
              glowColor: passed ? AppColors.leaf : AppColors.coral,
              front: const SizedBox(),
              back: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: passed ? AppColors.leafGreen.withValues(alpha: .12) : AppColors.coral.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: passed ? AppColors.leaf : AppColors.coral, width: 2),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(passed ? Icons.check_circle : Icons.refresh, color: passed ? AppColors.leaf : AppColors.coral, size: 30),
                    const SizedBox(height: 10),
                    Text(
                      '"${resultCard?['verse'] ?? widget.card['verse'] ?? ''}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4, color: AppColors.deepEmerald),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.card['reference']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.deepEmerald),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              passed
                  ? "🎉 You remembered it! (${result['similarity']}% match) This verse is now mastered."
                  : "Not quite yet (${result['similarity']}% match) — no worries, keep reviewing and you'll get it. It stays in your list.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: passed ? AppColors.leaf : AppColors.coral,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Done'),
              ),
            ),
            if (passed && nextSuggested != null) ...[
              const SizedBox(height: 24),
              GlassPanel(
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.deepEmerald),
                    const SizedBox(height: 8),
                    const Text('New Memory Card Ready!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      '${nextSuggested['reference']} will be ready to recall in 7 days once you add it.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Maybe Later'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _addNextCard(nextSuggested['id'].toString()),
                            child: const Text('Add This Card'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
