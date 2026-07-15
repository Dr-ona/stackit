import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../models/capture_payload.dart';
import '../../models/language_pair.dart';
import '../../models/vocabulary_entry.dart';
import '../review/review_page.dart';
import 'capture_preview_sheet.dart';
import 'account_settings_sheet.dart';
import 'language_pair_sheet.dart';
import 'library_entry_tile.dart';
import 'translation_meaning_list.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_entry_detail_sheet.dart';

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

class _VocabularyHomeState extends State<VocabularyHome> {
  int _page = 0;
  bool _sheetOpen = false;
  bool _languageSheetOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onControllerChanged());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
    if (widget.controller.isReady &&
        !widget.controller.hasChosenLanguagePair &&
        !_languageSheetOpen) {
      _languageSheetOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _chooseLanguage());
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCapture(capture));
  }

  Future<void> _chooseLanguage() async {
    if (!mounted) return;
    await showLanguagePairSheet(
      context,
      widget.controller,
      requiredSelection: true,
    );
    _languageSheetOpen = false;
    _onControllerChanged();
  }

  Future<void> _showCapture(CapturePayload capture) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFCF5),
      builder: (_) =>
          CapturePreviewSheet(capture: capture, controller: widget.controller),
    );
    _sheetOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Inbox(
        controller: widget.controller,
        authService: widget.authService,
        onStartReview: () => setState(() => _page = 1),
      ),
      ReviewPage(controller: widget.controller),
      _Library(controller: widget.controller),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (value) => setState(() => _page = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.refresh_rounded),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Library',
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
  });

  final VocabularyController controller;
  final AuthService authService;
  final VoidCallback onStartReview;

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
                        'Your word inbox',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'New words stay here until their first review.',
                        style: TextStyle(
                          color: Color(0xFF657069),
                          fontSize: 12,
                        ),
                      ),
                      if (controller.isSyncing) ...[
                        const SizedBox(height: 5),
                        const Text(
                          'Syncing securely…',
                          style: TextStyle(
                            color: Color(0xFF657069),
                            fontSize: 12,
                          ),
                        ),
                      ] else if (controller.cloudSyncError != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          controller.cloudSyncError!,
                          style: const TextStyle(
                            color: Color(0xFF9A5A16),
                            fontSize: 12,
                          ),
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
                    '${inboxEntries.length} new',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Account and settings',
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
              onPressed: () => showLanguagePairSheet(context, controller),
              icon: const Icon(Icons.translate_rounded),
              label: Text(controller.languagePair.label),
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
                label: Text(
                  'Start reviewing ${inboxEntries.length} new '
                  '${inboxEntries.length == 1 ? 'word' : 'words'}',
                ),
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
            child: _EmptyInbox(
              pair: controller.languagePair,
              totalSaved: controller.entries.length,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
  const _EmptyInbox({required this.pair, required this.totalSaved});

  final LanguagePair pair;
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
            totalSaved == 0 ? 'Meet a word worth keeping?' : 'Inbox clear',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            totalSaved == 0
                ? 'Highlight ${pair.source.label} text in another app, then choose “Stackit”. '
                      'If it is not listed, tap Share and choose Stackit instead.'
                : 'No new words are waiting. Your $totalSaved saved '
                      '${totalSaved == 1 ? 'word is' : 'words are'} still searchable in Library.',
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
                          Container(
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
                        ],
                      ),
                      const SizedBox(height: 6),
                      TranslationMeaningList(
                        translations: entry.translations,
                        language: entry.targetLanguage,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pronounce',
                  onPressed: () =>
                      controller.speak(entry.sourceText, entry.sourceLanguage),
                  icon: const Icon(Icons.volume_up_outlined),
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
              entry.translations.any(
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
            'Library',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'All ${widget.controller.entries.length} saved words — new and reviewed.',
            style: const TextStyle(color: Color(0xFF657069)),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search English or Arabic',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty
                          ? 'Your library is empty.'
                          : 'No matches found.',
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
