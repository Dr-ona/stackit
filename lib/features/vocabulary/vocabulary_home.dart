import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/capture_payload.dart';
import '../../models/language_pair.dart';
import '../../models/vocabulary_entry.dart';
import '../review/review_page.dart';
import 'capture_preview_sheet.dart';
import 'account_settings_sheet.dart';
import 'language_pair_sheet.dart';
import 'library_entry_tile.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_entry_detail_sheet.dart';
import 'vocabulary_sense_list.dart';

class VocabularyHome extends StatefulWidget {
  const VocabularyHome({
    super.key,
    required this.controller,
    required this.authService,
  });

  final VocabularyController controller;
  final AuthService authService;

  @override
  State<VocabularyHome> createState() => _VocabularyHomeState();
}

class _VocabularyHomeState extends State<VocabularyHome>
    with WidgetsBindingObserver {
  int _page = 0;
  bool _sheetOpen = false;
  bool _languageSheetOpen = false;
  bool _uiWorkScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
    _onControllerChanged();
    unawaited(widget.controller.pollPlatformCapture());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.pollPlatformCapture());
    }
  }

  void _onControllerChanged() {
    if (!mounted || _uiWorkScheduled) return;
    _uiWorkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uiWorkScheduled = false;
      if (!mounted) return;
      setState(() {});
      _drainPendingUiWork();
    });
  }

  void _drainPendingUiWork() {
    if (widget.controller.isReady &&
        !widget.controller.hasChosenTargetLanguage &&
        !_languageSheetOpen) {
      _languageSheetOpen = true;
      unawaited(_chooseLanguage());
      return;
    }
    if (_sheetOpen ||
        _languageSheetOpen ||
        widget.controller.pendingCapture == null) {
      return;
    }
    final capture = widget.controller.takePendingCapture();
    if (capture == null) return;
    _sheetOpen = true;
    unawaited(_showCapture(capture));
  }

  Future<void> _chooseLanguage() async {
    if (!mounted) return;
    try {
      await showTargetLanguageSheet(
        context,
        widget.controller,
        requiredSelection: true,
      );
    } finally {
      _languageSheetOpen = false;
      _onControllerChanged();
    }
  }

  Future<void> _showCapture(CapturePayload capture) async {
    if (!mounted) return;
    try {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFFFFCF5),
        builder: (_) => CapturePreviewSheet(
          capture: capture,
          controller: widget.controller,
        ),
      );
      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.savedForReview(capture.text))),
        );
        if (capture.isManual) {
          final entry = widget.controller.newestEntryForText(capture.text);
          if (entry != null && mounted) {
            await showVocabularyEntryDetails(
              context,
              entry: entry,
              controller: widget.controller,
            );
          }
        }
      }
    } finally {
      _sheetOpen = false;
      _onControllerChanged();
    }
  }

  Future<void> _addWordManually() async {
    var input = '';
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.addWord),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) => input = value,
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          decoration: InputDecoration(
            labelText: context.l10n.wordOrPhrase,
            hintText: context.l10n.wordOrPhraseHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, input.trim()),
            child: Text(context.l10n.add),
          ),
        ],
      ),
    );
    if (!mounted || text == null || text.trim().isEmpty) return;
    final capture = CapturePayload.manual(text: text.trim());
    if (_sheetOpen || _languageSheetOpen) {
      await widget.controller.receiveCapture(capture);
      return;
    }
    _sheetOpen = true;
    await _showCapture(capture);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Inbox(
        controller: widget.controller,
        authService: widget.authService,
        onStartReview: () => setState(() => _page = 1),
        onManualAdd: _addWordManually,
      ),
      ReviewPage(controller: widget.controller),
      _Library(controller: widget.controller),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (value) => setState(() => _page = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: context.l10n.inbox,
          ),
          NavigationDestination(
            icon: const Icon(Icons.refresh_rounded),
            selectedIcon: const Icon(Icons.refresh),
            label: context.l10n.review,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: context.l10n.library,
          ),
        ],
      ),
    );
  }
}

class _Inbox extends StatelessWidget {
  const _Inbox({
    required this.controller,
    required this.authService,
    required this.onStartReview,
    required this.onManualAdd,
  });

  final VocabularyController controller;
  final AuthService authService;
  final VoidCallback onStartReview;
  final VoidCallback onManualAdd;

  @override
  Widget build(BuildContext context) {
    final inboxEntries = controller.inboxEntries;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STACKIT',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: const Color(0xFF356859),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.wordInbox,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.l10n.newWordsStay,
                        style: const TextStyle(
                          color: Color(0xFF657069),
                          fontSize: 12,
                        ),
                      ),
                      if (controller.isSyncing) ...[
                        const SizedBox(height: 5),
                        Text(
                          context.l10n.syncing,
                          style: const TextStyle(
                            color: Color(0xFF657069),
                            fontSize: 12,
                          ),
                        ),
                      ] else if (controller.cloudSyncError != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                controller.cloudSyncError!,
                                style: const TextStyle(
                                  color: Color(0xFF9A5A16),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: controller.isSyncing
                                  ? null
                                  : controller.retryCloudSync,
                              child: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3ECE6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    context.l10n.newCount(inboxEntries.length),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: context.l10n.accountAndSettings,
                  onPressed: () => showAccountSettings(
                    context,
                    controller: controller,
                    authService: authService,
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          sliver: SliverToBoxAdapter(
            child: OutlinedButton.icon(
              onPressed: () => showTargetLanguageSheet(context, controller),
              icon: const Icon(Icons.translate_rounded),
              label: Text(
                '${controller.languagePair.source.nativeLabel} → '
                '${controller.languagePair.target.nativeLabel}',
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          sliver: SliverToBoxAdapter(
            child: FilledButton.tonalIcon(
              onPressed: onManualAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.addWordDirectly),
            ),
          ),
        ),
        if (controller.isReady && inboxEntries.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            sliver: SliverToBoxAdapter(
              child: FilledButton.icon(
                onPressed: onStartReview,
                icon: const Icon(Icons.school_outlined),
                label: Text(context.l10n.startReviewing(inboxEntries.length)),
              ),
            ),
          ),
        if (!controller.isReady)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (inboxEntries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyInbox(totalSaved: controller.entries.length),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverList.separated(
              itemCount: inboxEntries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _WordCard(entry: inboxEntries[index], controller: controller),
            ),
          ),
      ],
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.totalSaved});

  final int totalSaved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: Color(0xFFE3ECE6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              totalSaved == 0 ? Icons.text_fields_rounded : Icons.check_rounded,
              size: 38,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            totalSaved == 0 ? context.l10n.meetAWord : context.l10n.inboxClear,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            totalSaved == 0
                ? context.l10n.captureInstructions
                : context.l10n.clearInboxSummary(totalSaved),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF657069),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.entry, required this.controller});

  final VocabularyEntry entry;
  final VocabularyController controller;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFB94D48),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => controller.delete(entry.id),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          onTap: () => showVocabularyEntryDetails(
            context,
            entry: entry,
            controller: controller,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.sourceText,
                              textDirection: _textDirection(
                                entry.sourceLanguage,
                              ),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ExcludeSemantics(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC6DDD2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Color(0xFF275E50),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      VocabularySenseList(
                        senses: entry.senses,
                        sourceText: entry.sourceText,
                        sourceLanguage: entry.sourceLanguage,
                        targetLanguage: entry.targetLanguage,
                        compact: true,
                        showExamples: true,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: context.l10n.pronounce,
                  child: IconButton(
                    tooltip: context.l10n.pronounce,
                    onPressed: () =>
                        controller.speak(entry.sourceText, entry.sourceLanguage),
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Library extends StatefulWidget {
  const _Library({required this.controller});

  final VocabularyController controller;

  @override
  State<_Library> createState() => _LibraryState();
}

class _LibraryState extends State<_Library> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final matches = widget.controller.entries
        .where(
          (entry) =>
              entry.sourceText.toLowerCase().contains(normalized) ||
              entry.allTranslations.any(
                (translation) => translation.toLowerCase().contains(normalized),
              ),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.library,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            context.l10n.librarySummary(widget.controller.entries.length),
            style: const TextStyle(color: Color(0xFF657069)),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: context.l10n.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3ECE6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 34,
                              color: Color(0xFF356859),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            query.isEmpty
                                ? context.l10n.emptyLibraryTitle
                                : context.l10n.noMatches,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (query.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.emptyLibraryHint,
                              style: const TextStyle(
                                color: Color(0xFF657069),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = matches[index];
                      return LibraryEntryTile(
                        entry: entry,
                        controller: widget.controller,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

TextDirection _textDirection(VocabularyLanguage language) {
  return language.isRtl ? TextDirection.rtl : TextDirection.ltr;
}
