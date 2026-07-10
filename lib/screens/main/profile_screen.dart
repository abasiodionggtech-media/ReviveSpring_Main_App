import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../core/app_strings.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/appearance_settings_sheet.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/premium_upgrade_sheet.dart';
import '../../widgets/section_header.dart';
import 'milestones_screen.dart';

const _privacyPolicyUrl = 'https://www.iubenda.com/privacy-policy/60287717';
const _cookiePolicyUrl =
    'https://www.iubenda.com/privacy-policy/60287717/cookie-policy';
const _supportEmail = 'support@revivespring.com';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingLanguage = false;
  bool _savingBibleVersion = false;
  bool _savingReminder = false;
  bool _dailyEmails = true;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  bool _deletingAccount = false;
  String _deleteError = '';
  final _deleteReasonController = TextEditingController();
  final _deleteFeedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = widget.controller.user;
    _dailyEmails = user?.dailyEmailEnabled ?? true;
    _reminderHour = user?.reminderHour ?? 9;
    _reminderMinute = user?.reminderMinute ?? 0;
  }

  @override
  void dispose() {
    _deleteReasonController.dispose();
    _deleteFeedbackController.dispose();
    super.dispose();
  }

  Future<void> _openLegalUrl(String url, String errorMessage) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  void _openAboutPage(String language) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AboutContactPage(language: language),
      ),
    );
  }

  Future<void> _deleteAccount(String Function(String en, String fr) t) async {
    final reason = _deleteReasonController.text.trim();
    final feedback = _deleteFeedbackController.text.trim();
    if (reason.length < 3 || feedback.length < 5 || _deletingAccount) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Delete account?', 'Supprimer le compte ?')),
        content: Text(
          t(
            'This permanently deletes your ReviveSpring account and related records. This cannot be undone.',
            'Cela supprime definitivement votre compte ReviveSpring et les donnees associees. Cette action est irreversible.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', 'Annuler')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Delete account', 'Supprimer le compte')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingAccount = true;
      _deleteError = '';
    });
    final error = await widget.controller.deleteAccount(
      reason: reason,
      feedback: feedback,
    );
    if (!mounted) return;
    setState(() {
      _deletingAccount = false;
      _deleteError = error ?? '';
    });
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.user;
    final language = widget.controller.language;
    final messenger = ScaffoldMessenger.of(context);
    String t(String en, String fr) => AppStrings.of(language, en, fr);

    return ListView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        SectionHeader(
          title: t('My Profile', 'Mon profil'),
          subtitle: t(
            'Personal settings and testimony.',
            'Parametres personnels et temoignage.',
          ),
          icon: Icons.person,
        ),
        const SizedBox(height: 18),
        GlassPanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.sky.withValues(alpha: .25),
                backgroundImage:
                    user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: AppColors.deepEmerald,
                        size: 34,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Friend',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${(user?.plan ?? 'free').toUpperCase()} PLAN',
                      style: const TextStyle(
                        color: AppColors.deepEmerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Language', 'Langue'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: language == 'fr' ? 'fr' : 'en',
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.iconCream.withValues(alpha: .55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'fr', child: Text('Francais')),
                ],
                onChanged: _savingLanguage
                    ? null
                    : (value) async {
                        if (value == null) return;
                        setState(() => _savingLanguage = true);
                        final error = await widget.controller.updateLanguage(
                          value,
                        );
                        if (!mounted) return;
                        setState(() => _savingLanguage = false);
                        if (error != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Bible Version', 'Version de la Bible'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t(
                  'Choose the translation used for your daily verse and Verse of the Moment.',
                  'Choisissez la traduction utilisee pour votre verset du jour.',
                ),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: const {'NIV', 'KJV', 'NLT', 'ESV'}.contains(widget.controller.user?.bibleVersion)
                    ? widget.controller.user!.bibleVersion
                    : 'NIV',
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.iconCream.withValues(alpha: .55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'NIV', child: Text('NIV — New International Version')),
                  DropdownMenuItem(value: 'KJV', child: Text('KJV — King James Version')),
                  DropdownMenuItem(value: 'NLT', child: Text('NLT — New Living Translation')),
                  DropdownMenuItem(value: 'ESV', child: Text('ESV — English Standard Version')),
                ],
                onChanged: _savingBibleVersion
                    ? null
                    : (value) async {
                        if (value == null) return;
                        setState(() => _savingBibleVersion = true);
                        final error = await widget.controller.updateBibleVersion(value);
                        if (!mounted) return;
                        setState(() => _savingBibleVersion = false);
                        if (error != null) {
                          messenger.showSnackBar(SnackBar(content: Text(error)));
                        }
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: ListTile(
            leading: const Icon(
              Icons.font_download_outlined,
              color: AppColors.deepEmerald,
            ),
            title: Text(t('Appearance', 'Apparence')),
            subtitle: Text(
              t(
                '${widget.controller.fontFamily} · ${(widget.controller.fontScale * 100).round()}% text size',
                '${widget.controller.fontFamily} · ${(widget.controller.fontScale * 100).round()}% taille du texte',
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => AppearanceSettingsSheet.show(context, widget.controller),
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: ListTile(
            leading: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.deepEmerald,
            ),
            title: Text(t('Sign-In Method', 'Methode de connexion')),
            subtitle: Text((user?.authProvider ?? 'email').toUpperCase()),
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: ListTile(
            leading: Icon(
              user?.hasPassword == true ? Icons.lock_outline : Icons.lock_open_outlined,
              color: AppColors.deepEmerald,
            ),
            title: Text(
              user?.hasPassword == true
                  ? t('Change Password', 'Changer le mot de passe')
                  : t('Create a Password', 'Creer un mot de passe'),
            ),
            subtitle: Text(
              user?.hasPassword == true
                  ? t('Update the password for this account', 'Mettez a jour le mot de passe de ce compte')
                  : t(
                      'Add a password so you can also sign in with email, not just Google',
                      'Ajoutez un mot de passe pour aussi vous connecter par e-mail, pas seulement avec Google',
                    ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _PasswordSheet.show(context, widget.controller, hasPassword: user?.hasPassword == true),
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: ListTile(
            leading: const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.deepEmerald,
            ),
            title: Text(t('Faith Milestones', 'Etapes de foi')),
            subtitle: Text(
              t('View your earned badges', 'Voir vos badges obtenus'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MilestonesScreen(controller: widget.controller),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.deepEmerald.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.deepEmerald,
              ),
            ),
            title: Text(
              t('About ReviveSpring', 'A propos de ReviveSpring'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              t(
                'Contact us, support email, and app information.',
                'Contact, e-mail de support et informations sur l application.',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openAboutPage(language),
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Premium access', 'Acces premium'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.isAdmin == true
                    ? t(
                        'Admin accounts are automatically premium and will not see ads.',
                        'Les comptes admin sont automatiquement premium et ne voient pas de publicites.',
                      )
                    : user?.isPremium == true
                    ? t(
                        'Your account is premium. Ads are removed and premium features stay unlocked.',
                        'Votre compte est premium. Les publicites sont retirees et les fonctions premium restent debloquees.',
                      )
                    : t(
                        'Free accounts can use AI after a short ad and may see app ads outside onboarding. Upgrade on Android through Google Play to remove ads.',
                        'Les comptes gratuits peuvent utiliser l IA apres une courte pub et peuvent voir des pubs dans l application hors onboarding. Passez premium sur Android via Google Play pour retirer les pubs.',
                      ),
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 14),
              if (user?.isAdmin == true)
                AnimatedPrimaryButton(
                  label: t(
                    'Admin premium active',
                    'Premium administrateur actif',
                  ),
                  icon: Icons.verified,
                  onPressed: null,
                )
              else if (user?.isPremium == true)
                AnimatedPrimaryButton(
                  label: t('Subscribed', 'Abonne'),
                  icon: Icons.verified,
                  onPressed: null,
                )
              else
                AnimatedPrimaryButton(
                  label: t(
                    'Activate Google Play Billing',
                    'Activer Google Play Billing',
                  ),
                  icon: Icons.workspace_premium_outlined,
                  onPressed: () =>
                      PremiumUpgradeSheet.show(context, widget.controller),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            children: [
              SwitchListTile(
                value: _dailyEmails,
                onChanged: (value) async {
                  setState(() => _dailyEmails = value);
                  final result = await widget.controller.updateProfileSettings(
                    dailyEmailEnabled: value,
                    reminderHour: _reminderHour,
                    reminderMinute: _reminderMinute,
                    timezone: user?.timezone,
                  );
                  if (!mounted || result == null) return;
                  messenger.showSnackBar(SnackBar(content: Text(result)));
                },
                activeThumbColor: AppColors.leaf,
                title: Text(
                  t('Daily Prayer Emails', 'E-mails de priere quotidiens'),
                ),
                subtitle: Text(
                  t(
                    'Receive a personalized prayer every day.',
                    'Recevez chaque jour une priere personnalisee.',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _ProfileReminderCard(
                language: language,
                hour: _reminderHour,
                minute: _reminderMinute,
                onChanged: (hour, minute) {
                  setState(() {
                    _reminderHour = hour;
                    _reminderMinute = minute;
                  });
                },
              ),
              const SizedBox(height: 14),
              AnimatedPrimaryButton(
                label: _savingReminder
                    ? t('Saving...', 'Enregistrement...')
                    : t(
                        'Save Daily Email Time',
                        'Enregistrer l\'heure quotidienne',
                      ),
                icon: Icons.schedule_outlined,
                onPressed: _savingReminder
                    ? null
                    : () async {
                        setState(() => _savingReminder = true);
                        final result = await widget.controller
                            .updateProfileSettings(
                              dailyEmailEnabled: _dailyEmails,
                              reminderHour: _reminderHour,
                              reminderMinute: _reminderMinute,
                              timezone: user?.timezone,
                            );
                        if (!mounted) return;
                        setState(() => _savingReminder = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              result ??
                                  t(
                                    'Daily email timing updated.',
                                    'L\'heure des e-mails quotidiens a ete mise a jour.',
                                  ),
                            ),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Privacy', 'Confidentialite'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Review ReviveSpring policies in your browser.',
                  'Consultez les politiques de ReviveSpring dans votre navigateur.',
                ),
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openLegalUrl(
                      _privacyPolicyUrl,
                      t(
                        'Could not open the Privacy Policy.',
                        'Impossible d ouvrir la politique de confidentialite.',
                      ),
                    ),
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: Text(
                      t('Privacy Policy', 'Politique de confidentialite'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openLegalUrl(
                      _cookiePolicyUrl,
                      t(
                        'Could not open the Cookie Policy.',
                        'Impossible d ouvrir la politique relative aux cookies.',
                      ),
                    ),
                    icon: const Icon(Icons.cookie_outlined),
                    label: Text(
                      t('Cookie Policy', 'Politique relative aux cookies'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Delete account', 'Supprimer le compte'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'If you leave, please tell us why. Your feedback helps us improve ReviveSpring, then your account will be permanently removed.',
                  'Si vous partez, dites-nous pourquoi. Votre retour nous aide a ameliorer ReviveSpring, puis votre compte sera supprime definitivement.',
                ),
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _deleteReasonController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: t(
                    'Short reason for leaving',
                    'Raison breve du depart',
                  ),
                  filled: true,
                  fillColor: AppColors.iconCream.withValues(alpha: .55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deleteFeedbackController,
                minLines: 3,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: t(
                    'What made you decide to delete your account?',
                    'Pourquoi avez-vous decide de supprimer votre compte ?',
                  ),
                  filled: true,
                  fillColor: AppColors.iconCream.withValues(alpha: .55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_deleteError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _deleteError,
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _deleteReasonController.text.trim().length >= 3 &&
                          _deleteFeedbackController.text.trim().length >= 5 &&
                          !_deletingAccount
                      ? () => _deleteAccount(t)
                      : null,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(
                    _deletingAccount
                        ? t('Deleting account...', 'Suppression du compte...')
                        : t('Delete my account', 'Supprimer mon compte'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if ((user?.authProvider ?? 'email').toLowerCase() == 'email')
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResetPasswordScreen(
                    controller: widget.controller,
                    initialEmail: user?.email,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.lock_reset),
            label: Text(t('Reset Password', 'Reinitialiser le mot de passe')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepEmerald,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if ((user?.authProvider ?? 'email').toLowerCase() == 'email')
          const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: widget.controller.logout,
          icon: const Icon(Icons.logout),
          label: Text(t('Sign Out', 'Se deconnecter')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.coral,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _AboutContactPage extends StatelessWidget {
  const _AboutContactPage({required this.language});

  final String language;

  Future<void> _emailSupport(BuildContext context) async {
    final subject = Uri.encodeComponent('ReviveSpring Support');
    final uri = Uri.parse('mailto:$_supportEmail?subject=$subject');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.of(
            language,
            'No email app was found. Support email copied instead.',
            'Aucune application e-mail trouvee. L e-mail de support a ete copie.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String fr) => AppStrings.of(language, en, fr);

    return Scaffold(
      backgroundColor: AppColors.iconCream,
      appBar: AppBar(
        backgroundColor: AppColors.iconCream,
        foregroundColor: AppColors.deepEmerald,
        elevation: 0,
        title: Text(t('About ReviveSpring', 'A propos de ReviveSpring')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.deepEmerald,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: AppColors.iconCream,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'ReviveSpring',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.deepEmerald,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'ReviveSpring helps you build a daily rhythm of prayer, Scripture, journaling, spiritual goals, and faith-based encouragement.',
                    'ReviveSpring vous aide a construire un rythme quotidien de priere, Ecriture, journal, objectifs spirituels et encouragement fonde sur la foi.',
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Contact us', 'Nous contacter'),
                  style: const TextStyle(
                    color: AppColors.deepEmerald,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'For account help, billing questions, prayer-library issues, or app support, email us at:',
                    'Pour l aide au compte, la facturation, la bibliotheque de prieres ou le support de l application, ecrivez-nous a :',
                  ),
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _supportEmail,
                  style: const TextStyle(
                    color: AppColors.deepEmerald,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedPrimaryButton(
                  label: t('Email support', 'Ecrire au support'),
                  icon: Icons.email_outlined,
                  onPressed: () => _emailSupport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileReminderCard extends StatelessWidget {
  const _ProfileReminderCard({
    required this.language,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final String language;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteIndex = (minute / 5).round().clamp(0, 11);
    final selectedMinute = minuteIndex * 5;
    String t(String en, String fr) => AppStrings.of(language, en, fr);

    int to24Hour(int displayHour, String selectedPeriod) {
      final base = displayHour % 12;
      return selectedPeriod == 'PM' ? base + 12 : base;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deepEmerald.withValues(alpha: .92),
                AppColors.leafGreen.withValues(alpha: .74),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: AppColors.iconCream,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(
                        'Your daily sacred pause',
                        'Votre pause sacree quotidienne',
                      ),
                      style: const TextStyle(
                        color: AppColors.iconCream,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      t(
                        'Choose the time your daily prayer email should arrive.',
                        'Choisissez l\'heure de reception de votre e-mail de priere quotidien.',
                      ),
                      style: const TextStyle(
                        color: Color(0xD9FFFFFF),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.deepEmerald.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '${hour12.toString().padLeft(2, '0')} : ${selectedMinute.toString().padLeft(2, '0')} $period',
            style: const TextStyle(
              color: AppColors.deepEmerald,
              fontSize: 28,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 218,
          child: Row(
            children: [
              Expanded(
                child: _ProfileReminderWheel<int>(
                  label: t('Hour', 'Heure'),
                  values: List<int>.generate(12, (index) => index + 1),
                  selectedIndex: hour12 - 1,
                  format: (value) => value.toString().padLeft(2, '0'),
                  onSelected: (value) =>
                      onChanged(to24Hour(value, period), selectedMinute),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ProfileReminderWheel<int>(
                  label: t('Minute', 'Minute'),
                  values: List<int>.generate(12, (index) => index * 5),
                  selectedIndex: minuteIndex,
                  format: (value) => value.toString().padLeft(2, '0'),
                  onSelected: (value) => onChanged(hour, value),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ProfileReminderWheel<String>(
                  label: t('Period', 'Periode'),
                  values: const ['AM', 'PM'],
                  selectedIndex: period == 'AM' ? 0 : 1,
                  format: (value) => value,
                  onSelected: (value) =>
                      onChanged(to24Hour(hour12, value), selectedMinute),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileReminderWheel<T> extends StatefulWidget {
  const _ProfileReminderWheel({
    required this.label,
    required this.values,
    required this.selectedIndex,
    required this.format,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final int selectedIndex;
  final String Function(T value) format;
  final ValueChanged<T> onSelected;

  @override
  State<_ProfileReminderWheel<T>> createState() =>
      _ProfileReminderWheelState<T>();
}

class _ProfileReminderWheelState<T> extends State<_ProfileReminderWheel<T>> {
  late final FixedExtentScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant _ProfileReminderWheel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        controller.hasClients &&
        controller.selectedItem != widget.selectedIndex) {
      controller.animateToItem(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            color: AppColors.deepEmerald.withValues(alpha: .66),
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.deepEmerald.withValues(alpha: .08),
                  ),
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.leafGreen.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.deepEmerald.withValues(alpha: .18),
                    ),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 52,
                diameterRatio: 1.35,
                perspective: .004,
                physics: const FixedExtentScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                overAndUnderCenterOpacity: .32,
                onSelectedItemChanged: (index) {
                  HapticFeedback.selectionClick();
                  widget.onSelected(widget.values[index]);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, index) => Center(
                    child: Text(
                      widget.format(widget.values[index]),
                      style: const TextStyle(
                        color: AppColors.deepEmerald,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet used for both "Create a Password" (Google accounts with no
/// password yet) and "Change Password" (accounts that already have one).
/// The verification requirement is unchanged for existing passwords: the
/// current password is still required before a new one is accepted.
class _PasswordSheet {
  static Future<void> show(BuildContext context, AppController controller, {required bool hasPassword}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PasswordSheetBody(controller: controller, hasPassword: hasPassword),
    );
  }
}

class _PasswordSheetBody extends StatefulWidget {
  const _PasswordSheetBody({required this.controller, required this.hasPassword});

  final AppController controller;
  final bool hasPassword;

  @override
  State<_PasswordSheetBody> createState() => _PasswordSheetBodyState();
}

class _PasswordSheetBodyState extends State<_PasswordSheetBody> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPassword = _newController.text;
    final confirm = _confirmController.text;
    if (newPassword.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _error = "Passwords don't match.");
      return;
    }
    if (widget.hasPassword && _currentController.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = widget.hasPassword
        ? await widget.controller.changePassword(currentPassword: _currentController.text, newPassword: newPassword)
        : await widget.controller.setPassword(newPassword);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.hasPassword ? 'Password updated.' : 'Password created — you can now sign in with email too.',
        ),
        backgroundColor: AppColors.deepEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.hasPassword ? 'Change Password' : 'Create a Password',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              widget.hasPassword
                  ? 'Enter your current password, then choose a new one.'
                  : 'Add a password so you can sign in with either Google or your email from now on.',
              style: const TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 18),
            if (widget.hasPassword) ...[
              TextField(
                controller: _currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 13)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Saving...' : (widget.hasPassword ? 'Update Password' : 'Create Password')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
