import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/glass_panel.dart';

class MemoryCardsScreen extends StatefulWidget {
  const MemoryCardsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await widget.controller.api.getMemoryCards();
      if (mounted) setState(() => _cards = cards);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _showQuiz(Map<String, dynamic> card) async {
    final passed = await showDialog<bool>(
      context: context,
      builder: (_) => _QuizDialog(reference: card['reference']?.toString() ?? ''),
    );
    if (passed == null) return;
    await _updateCard(card['id'].toString(), () => widget.controller.api.quizMemoryCard(card['id'].toString(), passed: passed));
    if (passed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Verse mastered!'), backgroundColor: AppColors.deepEmerald),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Scripture Memory Cards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                const Text(
                  'Add a verse, flip the flashcard to review it, then take the quiz after 7 days to master it.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                ..._cards.map((card) {
                  final added = card['added'] == true;
                  final mastered = card['mastered'] == true;
                  final quizUnlocked = card['quiz_unlocked'] == true;
                  final daysUntilQuiz = card['days_until_quiz'] as int?;
                  final busy = _busyId == card['id'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: added
                        ? _FlipCard(
                            card: card,
                            busy: busy,
                            onReview: () => _updateCard(card['id'].toString(), () => widget.controller.api.reviewMemoryCard(card['id'].toString())),
                            onQuiz: quizUnlocked ? () => _showQuiz(card) : null,
                            mastered: mastered,
                            daysUntilQuiz: daysUntilQuiz,
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
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({
    required this.card,
    required this.busy,
    required this.onReview,
    required this.onQuiz,
    required this.mastered,
    required this.daysUntilQuiz,
  });

  final Map<String, dynamic> card;
  final bool busy;
  final VoidCallback onReview;
  final VoidCallback? onQuiz;
  final bool mastered;
  final int? daysUntilQuiz;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(card['reference']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
              if (widget.mastered)
                const Icon(Icons.verified, color: AppColors.leaf)
              else if (widget.daysUntilQuiz != null && widget.daysUntilQuiz! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
                  child: Text('Quiz in ${widget.daysUntilQuiz}d', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.deepEmerald)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _flipped ? AppColors.deepEmerald : AppColors.leafGreen.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _flipped ? (card['verse']?.toString() ?? '') : 'Tap to reveal the verse',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _flipped ? Colors.white : AppColors.deepEmerald,
                  fontWeight: FontWeight.w700,
                  fontStyle: _flipped ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
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
              if (widget.onQuiz != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.busy ? null : widget.onQuiz,
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: const Text('Take Quiz'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizDialog extends StatelessWidget {
  const _QuizDialog({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Recite $reference'),
      content: const Text('Without peeking, can you recall this verse from memory?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Not yet')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('I got it!')),
      ],
    );
  }
}
