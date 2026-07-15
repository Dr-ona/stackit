import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/vocabulary_export_service.dart';
import 'vocabulary_controller.dart';

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
            'Account & settings',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.authService.currentUser?.email ??
                'Signed-in Stackit account',
            style: const TextStyle(color: Color(0xFF657069)),
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Daily review reminder'),
            subtitle: const Text('At 7:00 PM in your device time zone'),
            value: widget.controller.reviewRemindersEnabled,
            onChanged: _busy ? null : _setReminders,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Export vocabulary'),
            subtitle: Text(
              '${widget.controller.entries.length} entries as JSON',
            ),
            onTap: _busy ? null : _export,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            onTap: _showPrivacy,
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            onTap: _busy ? null : widget.authService.signOut,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.error,
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Delete account and cloud data'),
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
        _message('Notification permission was not granted.');
      }
    }
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
        title: const Text('Stackit privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'Stackit stores vocabulary on your device and, when signed in, in '
            'your private Firebase account. Gemini receives a selected term and '
            'only the context you choose to submit. We do not sell personal data. '
            'You can export your vocabulary or delete your account and cloud data '
            'from this screen. Contact: khalidona.bk@gmail.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
        title: const Text('Delete your Stackit account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your cloud vocabulary and Firebase account. '
              'Export first if you want a copy.',
            ),
            if (needsPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete permanently'),
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
        throw const AuthFlowException('You are not signed in.');
      }
      await widget.controller.deleteAccountData(userId);
      await widget.authService.deleteCurrentUser();
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) _message(error.message ?? 'Account deletion failed.');
    } on AuthFlowException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Account deletion failed. Please try again.');
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
