import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth_service.dart';
import '../../data/vocabulary_export_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/language_pair.dart';
import '../profile/profile_page.dart';
import 'language_pair_sheet.dart';
import 'vocabulary_controller.dart';

const _privacyUrl = 'https://github.com/Dr-ona/stackit/blob/codex/v0.1-release/docs/privacy.md';
const _termsUrl = 'https://github.com/Dr-ona/stackit/blob/codex/v0.1-release/docs/terms.md';

Future<void> showAccountSettings(
  BuildContext context, {
  required VocabularyController controller,
  required AuthService authService,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _AccountSettingsSheet(controller: controller, authService: authService),
  );
}

class _AccountSettingsSheet extends StatefulWidget {
  const _AccountSettingsSheet({
    required this.controller,
    required this.authService,
  });

  final VocabularyController controller;
  final AuthService authService;

  @override
  State<_AccountSettingsSheet> createState() => _AccountSettingsSheetState();
}

class _AccountSettingsSheetState extends State<_AccountSettingsSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            context.l10n.accountAndSettings,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.controller.userProfile?.displayName ??
                widget.authService.currentUser?.email ??
                context.l10n.learningProfile,
            style: const TextStyle(color: Color(0xFF657069)),
          ),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(context.l10n.learningProfile),
            subtitle: Text(
              widget.controller.userProfile?.onboardingCompleted == true
                  ? widget.authService.currentUser?.email ??
                        context.l10n.completeYourProfile
                  : context.l10n.completeYourProfile,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _busy ? null : _openProfile,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language_rounded),
            title: Text(context.l10n.interfaceLanguage),
            subtitle: Text(
              widget.controller.interfaceLanguage?.nativeLabel ??
                  context.l10n.systemDefault,
            ),
            onTap: _busy ? null : _chooseInterfaceLanguage,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.translate_rounded),
            title: Text(context.l10n.translationPreference),
            subtitle: Text(
              widget.controller.preferredTargetLanguage.nativeLabel,
            ),
            onTap: _busy
                ? null
                : () => showTargetLanguageSheet(context, widget.controller),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(context.l10n.dailyReminder),
            subtitle: Text(context.l10n.reminderTime),
            value: widget.controller.reviewRemindersEnabled,
            onChanged: _busy ? null : _setReminders,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(context.l10n.exportVocabulary),
            subtitle: Text(
              context.l10n.jsonEntries(widget.controller.entries.length),
            ),
            onTap: _busy ? null : _export,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(context.l10n.privacyPolicy),
            onTap: _showPrivacy,
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded),
            title: Text(context.l10n.signOut),
            onTap: _busy ? null : widget.authService.signOut,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.error,
            leading: const Icon(Icons.delete_forever_outlined),
            title: Text(context.l10n.deleteAccount),
            onTap: _busy ? null : _deleteAccount,
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Future<void> _setReminders(bool enabled) async {
    setState(() => _busy = true);
    final changed = await widget.controller.setReviewReminders(enabled);
    if (mounted) {
      setState(() => _busy = false);
      if (enabled && !changed) {
        _message(context.l10n.notificationPermissionNotGranted);
      }
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(
          controller: widget.controller,
          authService: widget.authService,
        ),
      ),
    );
  }

  Future<void> _chooseInterfaceLanguage() async {
    const systemChoice = 'system';
    final selected = await showDialog<Object?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.interfaceLanguage),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, systemChoice),
            child: Text(context.l10n.systemDefault),
          ),
          for (final language in VocabularyLanguage.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, language),
              child: Text(language.nativeLabel),
            ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    await widget.controller.setInterfaceLanguage(
      selected == systemChoice ? null : selected as VocabularyLanguage,
    );
  }

  Future<void> _export() async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    await const VocabularyExportService().shareJson(
      widget.controller.exportJson(),
      sharePositionOrigin: origin,
    );
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.stackitPrivacy),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.privacyDescription),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(_privacyUrl)),
                child: Text(
                  context.l10n.privacyPolicy,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(_termsUrl)),
                child: Text(
                  context.l10n.termsOfService,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final password = TextEditingController();
    final needsPassword =
        widget.authService.requiresPasswordForReauthentication;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.deleteAccountDescription),
            if (needsPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.l10n.currentPassword,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.deletePermanently),
          ),
        ],
      ),
    );
    final currentPassword = password.text;
    password.dispose();
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.authService.reauthenticate(password: currentPassword);
      final userId = widget.authService.currentUser?.uid;
      if (userId == null) {
        throw const AuthFlowException('signed_out');
      }
      await widget.controller.deleteAccountData(userId);
      await widget.authService.deleteCurrentUser();
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) _message(error.message ?? context.l10n.accountDeletionFailed);
    } on AuthFlowException catch (error) {
      if (mounted) {
        _message(
          error.message == 'signed_out'
              ? context.l10n.signInRequired
              : context.l10n.accountDeletionFailed,
        );
      }
    } catch (_) {
      if (mounted) _message(context.l10n.accountDeletionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
