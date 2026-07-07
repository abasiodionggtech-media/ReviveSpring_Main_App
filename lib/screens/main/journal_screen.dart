import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../core/app_strings.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/section_header.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final text = TextEditingController();
  String? expandedEntryId;
  bool showAnsweredPrayers = false;

  String _entryKey(dynamic entry) =>
      (entry.id?.isNotEmpty == true ? entry.id! : '${entry.createdAt.toIso8601String()}-${entry.body.hashCode}');

  String _preview(String body) {
    const maxLength = 140;
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength).trimRight()}...';
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.controller.language;
    String t(String en, String fr) => AppStrings.of(language, en, fr);

    return ListView(
      key: const ValueKey('journal'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        SectionHeader(
          title: t('Prayer Journal', 'Journal de priere'),
          subtitle: t(
            'Record requests and celebrate answers.',
            'Consignez vos demandes et celebrez les reponses.',
          ),
          icon: Icons.edit_note,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _JournalTabButton(
                label: t('My Entries', 'Mes entrees'),
                selected: !showAnsweredPrayers,
                onTap: () => setState(() => showAnsweredPrayers = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _JournalTabButton(
                label: t('Answered Prayer Wall', 'Mur des prieres exaucees'),
                selected: showAnsweredPrayers,
                onTap: () => setState(() => showAnsweredPrayers = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (showAnsweredPrayers)
          ..._buildAnsweredPrayerWall(context, t)
        else ...[
          GlassPanel(
            child: Column(
              children: [
                AppTextField(
                  label: t(
                    'What are you carrying today?',
                    'Que portez-vous aujourd\'hui ?',
                  ),
                  icon: Icons.edit_note,
                  controller: text,
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                AnimatedPrimaryButton(
                  label: t('Add Entry', 'Ajouter une entree'),
                  icon: Icons.add,
                  onPressed: () async {
                    if (text.text.trim().isEmpty) return;
                    await widget.controller.addJournal(text.text.trim());
                    if (!mounted) return;
                    final newest = widget.controller.journal.isNotEmpty
                        ? widget.controller.journal.first
                        : null;
                    setState(() {
                      expandedEntryId =
                          newest == null ? null : _entryKey(newest);
                    });
                    text.clear();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...widget.controller.journal.map(
          (entry) {
            final entryKey = _entryKey(entry);
            final isExpanded = expandedEntryId == entryKey;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    expandedEntryId = isExpanded ? null : entryKey;
                  });
                },
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.createdAt.month}/${entry.createdAt.day}/${entry.createdAt.year}',
                                  style: const TextStyle(
                                    color: AppColors.deepEmerald,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isExpanded
                                      ? entry.body
                                      : _preview(entry.body),
                                  style: const TextStyle(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.leafGreen.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Icon(
                              isExpanded ? Icons.remove : Icons.add,
                              color: AppColors.deepEmerald,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        Text(
                          t(
                            'Tap again to collapse this journal entry.',
                            'Touchez encore pour reduire cette entree du journal.',
                          ),
                          style: TextStyle(
                            color: AppColors.deepEmerald.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ],
      ],
    );
  }

  List<Widget> _buildAnsweredPrayerWall(BuildContext context, String Function(String, String) t) {
    final controller = widget.controller;
    final answered = controller.answeredPrayers;
    final unanswered = controller.unansweredPrayers;
    return [
      if (answered.isEmpty)
        GlassPanel(
          child: Text(
            t(
              'No answered prayers yet. Mark a prayer as answered below when God moves.',
              'Aucune priere exaucee pour le moment. Marquez une priere comme exaucee ci-dessous.',
            ),
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        )
      else
        ...answered.map((prayer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.celebration_outlined, color: AppColors.leaf, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prayer['prayer_text']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ]),
                    if ((prayer['testimony'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(prayer['testimony'].toString(), style: const TextStyle(height: 1.45)),
                    ],
                  ],
                ),
              ),
            )),
      if (unanswered.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          t('Mark a prayer as answered', 'Marquer une priere comme exaucee'),
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepEmerald),
        ),
        const SizedBox(height: 10),
        ...unanswered.take(5).map((prayer) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                child: Row(children: [
                  Expanded(child: Text(prayer['prayer_text']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _showTestimonyDialog(context, prayer['id'].toString(), t),
                    child: Text(t('Answered', 'Exaucee')),
                  ),
                ]),
              ),
            )),
      ],
    ];
  }

  Future<void> _showTestimonyDialog(BuildContext context, String prayerId, String Function(String, String) t) async {
    final testimonyController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Share your testimony', 'Partagez votre temoignage')),
        content: TextField(
          controller: testimonyController,
          maxLines: 3,
          decoration: InputDecoration(hintText: t('How did God answer this?', 'Comment Dieu a-t-Il repondu ?')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t('Cancel', 'Annuler'))),
          FilledButton(
            onPressed: () async {
              await widget.controller.markPrayerAnswered(prayerId, testimony: testimonyController.text.trim());
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) setState(() {});
            },
            child: Text(t('Save', 'Enregistrer')),
          ),
        ],
      ),
    );
  }
}

class _JournalTabButton extends StatelessWidget {
  const _JournalTabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.deepEmerald : AppColors.leafGreen.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.deepEmerald,
          ),
        ),
      ),
    );
  }
}
