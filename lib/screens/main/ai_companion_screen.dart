import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_text_field.dart';

class AiCompanionScreen extends StatefulWidget {
  const AiCompanionScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AiCompanionScreen> createState() => _AiCompanionScreenState();
}

class _AiCompanionScreenState extends State<AiCompanionScreen> {
  final _input = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final result = await widget.controller.api.getCompanionHistory();
      final history = (result['messages'] as List? ?? const [])
          .map((m) => Map<String, String>.from({
                'role': (m as Map)['role']?.toString() ?? 'assistant',
                'content': m['content']?.toString() ?? '',
              }))
          .toList();
      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(history);
          if (_messages.isEmpty) {
            _messages.add({
              'role': 'assistant',
              'content': 'I\'m here with you — your Spiritual Companion. Tell me what\'s on your heart today.',
            });
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
      _input.clear();
    });
    try {
      final result = await widget.controller.api.sendCompanionMessage(text, language: widget.controller.language);
      if (mounted) {
        setState(() => _messages.add({'role': 'assistant', 'content': result['reply']?.toString() ?? ''}));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add({
              'role': 'assistant',
              'content': e.toString().contains('Premium')
                  ? 'The Spiritual Companion is a Premium feature — upgrade to unlock a companion that remembers your journey.'
                  : "I couldn't respond just now. Please try again.",
            }));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.controller.isPremiumUser;
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Spiritual Companion')),
      body: Column(
        children: [
          if (!isPremium)
            Container(
              width: double.infinity,
              color: AppColors.coral.withValues(alpha: .1),
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Premium feature — your companion remembers your recent moods and prayer topics across visits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.deepEmerald : AppColors.iconCream.withValues(alpha: .8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: TextStyle(color: isUser ? Colors.white : AppColors.ink, height: 1.4),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Share what\'s on your heart...',
                    icon: Icons.chat_bubble_outline,
                    controller: _input,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: AppColors.deepEmerald, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
