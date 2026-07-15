import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/glass_panel.dart';

/// Bible reading — free and open. No plan check, no paywall.
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> translations = [];
  List<Map<String, dynamic>> verses = [];

  String translation = 'KJV';
  String book = 'John';
  int chapter = 3;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadIndex();
    _loadChapter();
  }

  Future<void> _loadIndex() async {
    try {
      final b = await widget.controller.api.getBibleBooks();
      final t = await widget.controller.api.getBibleTranslations();
      if (mounted) setState(() { books = b; translations = t; });
    } catch (_) {
      // The reader still works without the index — it just can't show the
      // picker until this succeeds.
    }
  }

  Future<void> _loadChapter() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await widget.controller.api.getBibleChapter(translation, book, chapter);
      if (!mounted) return;
      setState(() {
        verses = List<Map<String, dynamic>>.from(data['verses'] as List);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        verses = [];
        error = e.toString();
        loading = false;
      });
    }
  }

  Map<String, dynamic>? get _currentBook {
    for (final b in books) {
      if (b['name'] == book) return b;
    }
    return null;
  }

  void _go(String nextBook, int nextChapter) {
    setState(() { book = nextBook; chapter = nextChapter; });
    _loadChapter();
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentBook;
    final totalChapters = (current?['chapters'] as int?) ?? 1;
    final order = (current?['order'] as int?) ?? 1;

    return ListView(
      key: const ValueKey('bible'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 130),
      children: [
        const Text('Bible', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.deepEmerald)),
        const SizedBox(height: 4),
        const Text(
          'Read freely. The whole Bible, always open to you.',
          style: TextStyle(color: AppColors.baseEarth, fontSize: 13),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: books.isEmpty ? null : _openPicker,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$book $chapter', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepEmerald)),
                    const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.deepEmerald),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _translationButton(),
          ],
        ),
        const SizedBox(height: 14),

        GlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : error != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: Column(children: [
                        Text(
                          translation == 'KJV'
                              ? "Couldn't load this chapter."
                              : "$translation isn't available yet.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (translation != 'KJV')
                          FilledButton(
                            onPressed: () { setState(() => translation = 'KJV'); _loadChapter(); },
                            child: const Text('Read the KJV instead'),
                          ),
                      ]),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$book $chapter',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.deepEmerald),
                        ),
                        const Divider(height: 22),
                        for (final v in verses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 15.5, height: 1.75, color: AppColors.ink),
                                children: [
                                  TextSpan(
                                    text: '${v['verse']} ',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.leaf,
                                      height: 1,
                                    ),
                                  ),
                                  TextSpan(text: '${v['text']}'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
        ),

        if (!loading && error == null && current != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: (chapter <= 1 && order == 1) ? null : () {
                  if (chapter > 1) return _go(book, chapter - 1);
                  final prev = books.firstWhere((b) => b['order'] == order - 1, orElse: () => {});
                  if (prev.isNotEmpty) _go(prev['name'] as String, prev['chapters'] as int);
                },
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Previous'),
              ),
              Text('$chapter / $totalChapters',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.baseEarth)),
              TextButton.icon(
                onPressed: (chapter >= totalChapters && order == 66) ? null : () {
                  if (chapter < totalChapters) return _go(book, chapter + 1);
                  final next = books.firstWhere((b) => b['order'] == order + 1, orElse: () => {});
                  if (next.isNotEmpty) _go(next['name'] as String, 1);
                },
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _translationButton() {
    return PopupMenuButton<String>(
      onSelected: (code) { setState(() => translation = code); _loadChapter(); },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => translations.map((t) {
        final available = t['available'] == true;
        return PopupMenuItem<String>(
          value: t['code'] as String,
          enabled: available,
          child: Row(
            children: [
              Text(t['code'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  available ? '${t['name']}' : '${t['name']} · coming soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: available ? AppColors.baseEarth : AppColors.baseEarth.withValues(alpha: .55),
                    fontStyle: available ? FontStyle.normal : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.deepEmerald.withValues(alpha: .25)),
        ),
        child: Row(children: [
          Text(translation, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepEmerald)),
          const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.deepEmerald),
        ]),
      ),
    );
  }

  void _openPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookPicker(
        books: books,
        current: book,
        onPick: (b, c) { Navigator.of(context).pop(); _go(b, c); },
      ),
    );
  }
}

class _BookPicker extends StatefulWidget {
  const _BookPicker({required this.books, required this.current, required this.onPick});

  final List<Map<String, dynamic>> books;
  final String current;
  final void Function(String book, int chapter) onPick;

  @override
  State<_BookPicker> createState() => _BookPickerState();
}

class _BookPickerState extends State<_BookPicker> {
  Map<String, dynamic>? picked;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .8,
      maxChildSize: .92,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.iconCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: picked == null ? _books(scroll) : _chapters(scroll),
      ),
    );
  }

  Widget _books(ScrollController scroll) {
    return ListView(
      controller: scroll,
      children: [
        const Center(child: Text('Choose a book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        const SizedBox(height: 16),
        for (final testament in ['Old Testament', 'New Testament']) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              testament.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: AppColors.leaf),
            ),
          ),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: widget.books.where((b) => b['testament'] == testament).map((b) {
              final on = b['name'] == widget.current;
              return GestureDetector(
                onTap: () {
                  if ((b['chapters'] as int) == 1) {
                    widget.onPick(b['name'] as String, 1);
                  } else {
                    setState(() => picked = b);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: on ? AppColors.deepEmerald : AppColors.panel,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withValues(alpha: .9)),
                  ),
                  child: Text(
                    b['name'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _chapters(ScrollController scroll) {
    final b = picked!;
    final count = b['chapters'] as int;
    return ListView(
      controller: scroll,
      children: [
        Row(children: [
          TextButton.icon(
            onPressed: () => setState(() => picked = null),
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('All books'),
          ),
        ]),
        Center(child: Text(b['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        const SizedBox(height: 14),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: List.generate(count, (i) {
            final c = i + 1;
            return GestureDetector(
              onTap: () => widget.onPick(b['name'] as String, c),
              child: Container(
                width: 48,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white.withValues(alpha: .9)),
                ),
                child: Text('$c', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            );
          }),
        ),
      ],
    );
  }
}
