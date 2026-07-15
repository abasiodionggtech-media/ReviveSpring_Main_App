import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/glass_panel.dart';

class MentorshipScreen extends StatefulWidget {
  const MentorshipScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends State<MentorshipScreen> {
  List<Map<String, dynamic>> _mentors = [];
  List<Map<String, dynamic>> _myMatches = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.controller.api.getMentors(),
        widget.controller.api.getMyMentorshipMatches(),
      ]);
      if (mounted) {
        setState(() {
          _mentors = results[0];
          _myMatches = results[1];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _becomeMentor() async {
    final bioController = TextEditingController();
    final bio = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Become a Mentor'),
        content: TextField(controller: bioController, maxLines: 3, decoration: const InputDecoration(hintText: 'A short bio about your walk with God')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(bioController.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (bio == null) return;
    try {
      await widget.controller.api.becomeMentor(bio: bio);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're now listed as a mentor."), backgroundColor: AppColors.deepEmerald),
        );
      }
    } catch (_) {}
  }

  Future<void> _requestMentor(String mentorUserId) async {
    setState(() => _busyId = mentorUserId);
    try {
      await widget.controller.api.requestMentor(mentorUserId);
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _respond(String matchId, bool accept) async {
    setState(() => _busyId = matchId);
    try {
      await widget.controller.api.respondToMentorshipMatch(matchId, accept: accept);
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _checkIn(String matchId) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check In'),
        content: TextField(controller: noteController, maxLines: 3, decoration: const InputDecoration(hintText: 'How is your walk with God this week?')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(noteController.text.trim()), child: const Text('Send')),
        ],
      ),
    );
    if (note == null || note.isEmpty) return;
    try {
      await widget.controller.api.mentorshipCheckIn(matchId, note);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        elevation: 0,
        title: const Text('Spiritual Mentorship'),
        actions: [TextButton(onPressed: _becomeMentor, child: const Text('Become a Mentor'))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                if (_myMatches.isNotEmpty) ...[
                  const Text('Your Mentorships', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 12),
                  ..._myMatches.map((match) {
                    final busy = _busyId == match['id'];
                    final status = match['status']?.toString() ?? 'pending';
                    final isMentorRole = match['role'] == 'mentor';
                    final checkIns = (match['check_ins'] as List? ?? const []);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${match['other_person'] ?? 'Someone'} (${isMentorRole ? "you're mentoring" : "your mentor"})', style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Status: $status', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            if (status == 'pending' && isMentorRole) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  OutlinedButton(onPressed: busy ? null : () => _respond(match['id'].toString(), false), child: const Text('Decline')),
                                  const SizedBox(width: 8),
                                  FilledButton(onPressed: busy ? null : () => _respond(match['id'].toString(), true), child: const Text('Accept')),
                                ],
                              ),
                            ],
                            if (status == 'active') ...[
                              const SizedBox(height: 10),
                              Text('${checkIns.length} check-ins', style: const TextStyle(color: AppColors.deepEmerald, fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: busy ? null : () => _checkIn(match['id'].toString()),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Check In'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 22),
                ],
                const Text('Available Mentors', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 12),
                ..._mentors.map((mentor) {
                  final busy = _busyId == mentor['mentor_user_id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassPanel(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mentor['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                                if ((mentor['bio'] as String?)?.isNotEmpty == true)
                                  Text(mentor['bio'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                          AnimatedPrimaryButton(
                            label: 'Request',
                            icon: Icons.handshake_outlined,
                            busy: busy,
                            onPressed: busy ? null : () => _requestMentor(mentor['mentor_user_id'].toString()),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_mentors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('No mentors available yet. Be the first!', style: TextStyle(color: AppColors.muted)),
                  ),
              ],
            ),
    );
  }
}
