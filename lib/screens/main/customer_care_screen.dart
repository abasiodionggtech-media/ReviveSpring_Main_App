import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/section_header.dart';

class CustomerCareScreen extends StatefulWidget {
  const CustomerCareScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final AppController controller;
  final VoidCallback onBack;

  @override
  State<CustomerCareScreen> createState() => _CustomerCareScreenState();
}

class _CustomerCareScreenState extends State<CustomerCareScreen> {
  final subject = TextEditingController();
  final message = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = message.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    final cleanSubject = subject.text.trim().isEmpty
        ? _subjectFromMessage(text)
        : subject.text.trim();
    final error = await widget.controller.submitSupportTicket(
      subject: cleanSubject,
      message: text,
    );
    if (!mounted) return;
    setState(() => sending = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    subject.clear();
    message.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent to ReviveSpring Care.')),
    );
  }

  String _subjectFromMessage(String value) {
    final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.length <= 42) return oneLine;
    return '${oneLine.substring(0, 42)}...';
  }

  Future<void> refreshTickets() async {
    await widget.controller.refreshSupportTickets();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshTickets,
      child: ListView(
        key: const ValueKey('customer-care-user'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          const SectionHeader(
            title: 'Customer Care',
            subtitle: 'Your private support space.',
            icon: Icons.support_agent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: refreshTickets,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh conversations',
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      color: AppColors.deepEmerald,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tell us what you need. Your message is saved securely and the care team can reply directly to your account.',
                        style: TextStyle(color: AppColors.muted, height: 1.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Subject',
                  icon: Icons.title,
                  controller: subject,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Write your message',
                  icon: Icons.chat_bubble_outline,
                  controller: message,
                  minLines: 4,
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                AnimatedPrimaryButton(
                  label: sending ? 'Sending...' : 'Send Message',
                  icon: Icons.send,
                  onPressed: sending ? null : sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (widget.controller.supportTickets.isEmpty)
            const GlassPanel(
              child: Text(
                'No support conversations yet. Pull down anytime to refresh.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else ...[
            const Text(
              'Your conversations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...widget.controller.supportTickets.map(
              (ticket) => _UserTicketCard(
                ticket: ticket,
                controller: widget.controller,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserTicketCard extends StatefulWidget {
  const _UserTicketCard({
    required this.ticket,
    required this.controller,
    required this.onChanged,
  });

  final Map<String, dynamic> ticket;
  final AppController controller;
  final VoidCallback onChanged;

  @override
  State<_UserTicketCard> createState() => _UserTicketCardState();
}

class _UserTicketCardState extends State<_UserTicketCard> {
  final reply = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  Future<void> sendReply() async {
    final ticketId = (widget.ticket['id'] ?? '').toString();
    final text = reply.text.trim();
    if (ticketId.isEmpty || text.isEmpty || sending) return;
    setState(() => sending = true);
    final error = await widget.controller.addSupportTicketMessage(
      ticketId: ticketId,
      message: text,
    );
    if (!mounted) return;
    setState(() => sending = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    reply.clear();
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply sent to ReviveSpring Care.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.ticket['messages'] is List
        ? widget.ticket['messages'] as List
        : const [];
    final subject = (widget.ticket['subject'] ?? '').toString().trim();
    final isClosed =
        (widget.ticket['status'] ?? 'open').toString().toLowerCase() ==
        'closed';
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.isEmpty ? 'Support conversation' : subject,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                (widget.ticket['status'] ?? 'open').toString().toUpperCase(),
                style: const TextStyle(
                  color: AppColors.leaf,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final raw in messages)
            Builder(
              builder: (context) {
                final item = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};
                final fromCare = item['role'] == 'admin';
                return Align(
                  alignment: fromCare
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .72,
                    ),
                    decoration: BoxDecoration(
                      color: fromCare
                          ? AppColors.leaf.withValues(alpha: .12)
                          : AppColors.deepEmerald,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromCare ? 'ReviveSpring Care' : 'You',
                          style: TextStyle(
                            color: fromCare
                                ? AppColors.deepEmerald
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (item['body'] ?? '').toString(),
                          style: TextStyle(
                            color: fromCare ? AppColors.muted : Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          if (isClosed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.leaf.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'This conversation has been closed by ReviveSpring Care. You can still review the full chat history here, but you cannot send new messages in this chat.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ),
          ] else ...[
            AppTextField(
              label: 'Continue this chat',
              icon: Icons.reply,
              controller: reply,
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            AnimatedPrimaryButton(
              label: sending ? 'Sending...' : 'Send Reply',
              icon: Icons.send,
              onPressed: sending ? null : sendReply,
            ),
          ],
        ],
      ),
    );
  }
}
