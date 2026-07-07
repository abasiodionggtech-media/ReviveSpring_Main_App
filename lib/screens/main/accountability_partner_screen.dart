import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/glass_panel.dart';

class AccountabilityPartnerScreen extends StatefulWidget {
  const AccountabilityPartnerScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AccountabilityPartnerScreen> createState() => _AccountabilityPartnerScreenState();
}

class _AccountabilityPartnerScreenState extends State<AccountabilityPartnerScreen> {
  final _codeController = TextEditingController();
  Map<String, dynamic>? _partner;
  String? _myInviteCode;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await widget.controller.api.getAccountabilityPartner();
      if (mounted) setState(() => _partner = result?['partner'] as Map<String, dynamic>?);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateInvite() async {
    setState(() => _busy = true);
    try {
      final result = await widget.controller.api.createAccountabilityInvite();
      if (mounted) setState(() => _myInviteCode = result['invite_code']?.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptInvite() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.controller.api.acceptAccountabilityInvite(code);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _nudge() async {
    setState(() => _busy = true);
    try {
      await widget.controller.api.sendAccountabilityNudge();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nudge sent! 👋'), backgroundColor: AppColors.deepEmerald),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(backgroundColor: AppColors.panel, elevation: 0, title: const Text('Accountability Partner')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepEmerald))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: _partner != null
                  ? [
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(backgroundColor: AppColors.deepEmerald, child: Icon(Icons.person, color: Colors.white)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_partner!['name']?.toString() ?? 'Your partner', style: const TextStyle(fontWeight: FontWeight.w900)),
                                      Text('${_partner!['current_streak'] ?? 0}-day streak', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AnimatedPrimaryButton(
                              label: 'Send a Nudge',
                              icon: Icons.notifications_active_outlined,
                              busy: _busy,
                              onPressed: _busy ? null : _nudge,
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [
                      const Text(
                        'Pair up with someone to stay consistent together. Generate an invite code to share, or enter one you received.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invite a Partner', style: TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 10),
                            if (_myInviteCode != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.leafGreen.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  'Share this code: $_myInviteCode',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.deepEmerald),
                                ),
                              )
                            else
                              AnimatedPrimaryButton(
                                label: 'Generate Invite Code',
                                icon: Icons.qr_code,
                                busy: _busy,
                                onPressed: _busy ? null : _generateInvite,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Have a Code?', style: TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 10),
                            AppTextField(label: 'Enter invite code', icon: Icons.key, controller: _codeController),
                            const SizedBox(height: 10),
                            AnimatedPrimaryButton(
                              label: 'Accept Invite',
                              icon: Icons.handshake_outlined,
                              busy: _busy,
                              onPressed: _busy ? null : _acceptInvite,
                            ),
                          ],
                        ),
                      ),
                    ],
            ),
    );
  }
}
