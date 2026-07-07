import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class VerseOfMomentDialog extends StatefulWidget {
  const VerseOfMomentDialog({super.key, required this.fetchVerse});

  final Future<Map<String, dynamic>> Function() fetchVerse;

  @override
  State<VerseOfMomentDialog> createState() => _VerseOfMomentDialogState();
}

class _VerseOfMomentDialogState extends State<VerseOfMomentDialog> {
  Map<String, dynamic>? verse;
  bool loading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    if (loading) return;
    setState(() {
      loading = true;
      hasError = false;
    });
    try {
      final result = await widget.fetchVerse();
      if (mounted) {
        setState(() {
          verse = result;
          hasError = false;
        });
      }
    } catch (_) {
      // Only show the error state if we have nothing else to display —
      // otherwise keep the previous verse on screen.
      if (mounted && verse == null) {
        setState(() => hasError = true);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.deepEmerald,
      insetPadding: const EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _loadNext,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: loading && verse == null
                          ? const CircularProgressIndicator(color: Colors.white, key: ValueKey('loading'))
                          : hasError && verse == null
                              ? Column(
                                  key: const ValueKey('error'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cloud_off_outlined, color: Colors.white.withValues(alpha: .7), size: 36),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Couldn't load a verse right now.",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Check your connection and tap anywhere to try again.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white.withValues(alpha: .65), fontSize: 13),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: ValueKey(verse?['reference']),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '"${verse?['verse'] ?? ''}"',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      verse?['reference']?.toString() ?? '',
                                      style: TextStyle(color: Colors.white.withValues(alpha: .8), fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      'Tap anywhere for another verse',
                                      style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 12),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
