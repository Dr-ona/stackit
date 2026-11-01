import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/filter_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/capture_payload.dart';
import '../../models/language_pair.dart';
import '../../models/vocabulary_entry.dart';
import '../review/review_page.dart';
import 'capture_preview_sheet.dart';
import 'account_settings_sheet.dart';
import 'language_pair_sheet.dart';
import 'library_entry_tile.dart';
import 'collection_picker_sheet.dart';
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
      final result = await showModalBottomSheet<CaptureResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFFFFCF5),
        builder: (_) => CapturePreviewSheet(
          capture: capture,
          controller: widget.controller,
        ),
      );
      if (result == CaptureResult.saved && mounted) {
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
      } else if (result == CaptureResult.viewExisting && mounted) {
        final entry = widget.controller.newestEntryForText(capture.text);
        if (entry != null && mounted) {
          await showVocabularyEntryDetails(
            context,
            entry: entry,
            controller: widget.controller,
          );
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

  Future<void> _addFromClipboard() async {
    final payload = await widget.controller.readClipboard();
    if (!mounted) return;
    if (payload == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.clipboardEmpty)));
      return;
    }
    if (_sheetOpen || _languageSheetOpen) {
      await widget.controller.receiveCapture(payload);
      return;
    }
    _sheetOpen = true;
    await _showCapture(payload);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Inbox(
        controller: widget.controller,
        authService: widget.authService,
        onStartReview: () => setState(() => _page = 1),
        onManualAdd: _addWordManually,
        onPasteClipboard: _addFromClipboard,
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
    required this.onPasteClipboard,
  });

  final VocabularyController controller;
  final AuthService authService;
  final VoidCallback onStartReview;
  final VoidCallback onManualAdd;
  final VoidCallback onPasteClipboard;

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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          sliver: SliverToBoxAdapter(
            child: FilledButton.tonalIcon(
              onPressed: onPasteClipboard,
              icon: const Icon(Icons.content_paste_rounded),
              label: Text(context.l10n.pasteFromClipboard),
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
          if (totalSaved == 0) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6D3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.howToCapture,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CaptureStep(step: '1', text: context.l10n.captureStep1),
                  const SizedBox(height: 6),
                  _CaptureStep(step: '2', text: context.l10n.captureStep2),
                  const SizedBox(height: 6),
                  _CaptureStep(step: '3', text: context.l10n.captureStep3),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.captureMissingHint,
                    style: const TextStyle(
                      color: Color(0xFF9A5A16),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      onDismissed: (_) async {
        final text = entry.sourceText;
        await controller.delete(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.entryDeleted(text)),
              action: SnackBarAction(
                label: context.l10n.undo,
                onPressed: () => controller.undoDelete(),
              ),
            ),
          );
        }
      },
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
                    onPressed: () => controller.speak(
                      entry.sourceText,
                      entry.sourceLanguage,
                    ),
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
  final Set<String> _selectedIds = {};
  LibraryFilter _filter = const LibraryFilter();
  final FilterService _filterService = const FilterService();

  bool get _isMultiSelectMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<VocabularyEntry> entries) {
    setState(() {
      if (_selectedIds.length == entries.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(entries.map((e) => e.id));
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _setQuickFilter({bool? favorite, EntryStatus? status}) {
    setState(() {
      var f = _filter.copyWith(searchQuery: query);
      if (status != null) {
        f = f.statuses.contains(status)
            ? f.copyWith(statuses: [])
            : f.copyWith(statuses: [status]);
      }
      if (favorite != null) {
        f = f.copyWith(favorite: f.favorite == true ? null : true);
      }
      _filter = f;
    });
  }

  void _applyFilter(LibraryFilter newFilter) {
    setState(() => _filter = newFilter.copyWith(searchQuery: query));
  }

  List<VocabularyEntry> get _filteredEntries {
    var entries = widget.controller.entries;
    if (_filter.searchQuery.isEmpty && query.isNotEmpty) {
      _filter = _filter.copyWith(searchQuery: query);
    }
    if (!_filter.isEmpty || query.isNotEmpty) {
      entries = _filterService.apply(
        entries,
        _filter.copyWith(searchQuery: query),
      );
    } else {
      entries = List.of(entries)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return entries;
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.confirmDeleteSelected),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.deleteSelected,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final count = _selectedIds.length;
    for (final id in _selectedIds) {
      await widget.controller.delete(id);
    }
    _clearSelection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectedCount(count)),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => widget.controller.undoDelete(),
          ),
        ),
      );
    }
  }

  Future<void> _bulkAddToCollection() async {
    final controller = widget.controller;
    final entries = controller.entries
        .where((e) => _selectedIds.contains(e.id))
        .toList();
    if (entries.isEmpty) return;
    final collection = await showCollectionPicker(
      context,
      controller: controller,
      entry: entries.first,
      selectOnly: true,
    );
    if (collection == null || !mounted) return;
    for (final entry in entries) {
      await controller.addToCollection(entry, collection.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectedCount(entries.length))),
      );
    }
  }

  Future<void> _bulkToggleFavorite() async {
    for (final id in _selectedIds) {
      final entry = widget.controller.entries.firstWhere(
        (e) => e.id == id,
        orElse: () => throw StateError('Entry $id not found'),
      );
      await widget.controller.toggleFavorite(entry);
    }
    _clearSelection();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilterBottomSheet(
        filter: _filter,
        controller: widget.controller,
        onApply: _applyFilter,
      ),
    );
  }

  bool get _hasActiveFilters =>
      _filter.languages.isNotEmpty ||
      _filter.statuses.isNotEmpty ||
      _filter.collectionIds.isNotEmpty ||
      _filter.tagIds.isNotEmpty ||
      _filter.favorite == true;

  @override
  Widget build(BuildContext context) {
    final matches = _filteredEntries;
    final controller = widget.controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.library,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isMultiSelectMode)
                TextButton(
                  onPressed: () => _selectAll(matches),
                  child: Text(
                    _selectedIds.length == matches.length
                        ? context.l10n.deselectAll
                        : context.l10n.selectAll,
                  ),
                ),
              if (!_isMultiSelectMode)
                IconButton(
                  onPressed: _showFilterSheet,
                  icon: Badge(
                    isLabelVisible: _hasActiveFilters,
                    label: Text(
                      (_filter.languages.length +
                              _filter.statuses.length +
                              _filter.collectionIds.length +
                              _filter.tagIds.length +
                              (_filter.favorite == true ? 1 : 0))
                          .toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.tune_rounded),
                  ),
                  tooltip: 'Filters',
                ),
            ],
          ),
          const SizedBox(height: 5),
          if (_isMultiSelectMode)
            Text(
              context.l10n.selectedCount(_selectedIds.length),
              style: const TextStyle(
                color: Color(0xFF356859),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              context.l10n.librarySummary(matches.length),
              style: const TextStyle(color: Color(0xFF657069)),
            ),
          const SizedBox(height: 12),
          if (!_isMultiSelectMode) ...[
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: !_hasActiveFilters,
                    onTap: () => setState(() {
                      _filter = const LibraryFilter();
                      query = '';
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Favorites',
                    icon: Icons.favorite,
                    selected: _filter.favorite == true,
                    onTap: () => _setQuickFilter(favorite: true),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'New',
                    selected: _filter.statuses.contains(EntryStatus.newEntry),
                    onTap: () => _setQuickFilter(status: EntryStatus.newEntry),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Due',
                    selected: _filter.statuses.contains(EntryStatus.due),
                    onTap: () => _setQuickFilter(status: EntryStatus.due),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Mastered',
                    selected: _filter.statuses.contains(EntryStatus.mastered),
                    onTap: () => _setQuickFilter(status: EntryStatus.mastered),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            onChanged: (value) => setState(() {
              query = value;
              _filter = _filter.copyWith(searchQuery: value);
            }),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3ECE6),
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
                            query.isEmpty && !_hasActiveFilters
                                ? context.l10n.emptyLibraryTitle
                                : context.l10n.noMatches,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          if (query.isEmpty && !_hasActiveFilters) ...[
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
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: matches.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = matches[index];
                            return LibraryEntryTile(
                              entry: entry,
                              controller: controller,
                              selected: _selectedIds.contains(entry.id),
                              onTap: _isMultiSelectMode
                                  ? () => _toggleSelection(entry.id)
                                  : null,
                              onLongPress: () => _toggleSelection(entry.id),
                            );
                          },
                        ),
                      ),
                      if (_isMultiSelectMode) ...[
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: context.l10n.addToCollection,
                                  onPressed: _bulkAddToCollection,
                                  icon: const Icon(
                                    Icons.collections_bookmark_outlined,
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.l10n.pronounce,
                                  onPressed: _bulkToggleFavorite,
                                  icon: const Icon(Icons.favorite_border),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: context.l10n.deleteSelected,
                                  onPressed: _deleteSelected,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton(
                                  onPressed: _clearSelection,
                                  child: Text(context.l10n.cancel),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF356859) : const Color(0xFFF0F4F1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : const Color(0xFF356859),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF356859),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.filter,
    required this.controller,
    required this.onApply,
  });

  final LibraryFilter filter;
  final VocabularyController controller;
  final ValueChanged<LibraryFilter> onApply;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late LibraryFilter _current;

  @override
  void initState() {
    super.initState();
    _current = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final collections = controller.collections;
    final tags = controller.tags;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Language
            _FilterSection(
              title: 'Language',
              children: VocabularyLanguage.values.map((lang) {
                final selected = _current.languages.contains(lang);
                return FilterChip(
                  label: Text(lang.label),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      final langs = List<VocabularyLanguage>.from(
                        _current.languages,
                      );
                      if (val) {
                        langs.add(lang);
                      } else {
                        langs.remove(lang);
                      }
                      _current = _current.copyWith(languages: langs);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Status
            _FilterSection(
              title: 'Status',
              children: EntryStatus.values.map((status) {
                final selected = _current.statuses.contains(status);
                return FilterChip(
                  label: Text(_statusLabel(status)),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      final statuses = List<EntryStatus>.from(
                        _current.statuses,
                      );
                      if (val) {
                        statuses.add(status);
                      } else {
                        statuses.remove(status);
                      }
                      _current = _current.copyWith(statuses: statuses);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Favorites
            _FilterSection(
              title: 'Favorites',
              children: [
                FilterChip(
                  label: const Text('Favorites only'),
                  selected: _current.favorite == true,
                  onSelected: (val) {
                    setState(
                      () => _current = _current.copyWith(
                        favorite: val ? true : null,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Collections
            if (collections.isNotEmpty) ...[
              _FilterSection(
                title: 'Collections',
                children: collections.map((col) {
                  final selected = _current.collectionIds.contains(col.id);
                  return FilterChip(
                    label: Text(col.name),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        final ids = List<String>.from(_current.collectionIds);
                        if (val) {
                          ids.add(col.id);
                        } else {
                          ids.remove(col.id);
                        }
                        _current = _current.copyWith(collectionIds: ids);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Tags
            if (tags.isNotEmpty) ...[
              _FilterSection(
                title: 'Tags',
                children: tags.map((tag) {
                  final selected = _current.tagIds.contains(tag.id);
                  return FilterChip(
                    label: Text(tag.name),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        final ids = List<String>.from(_current.tagIds);
                        if (val) {
                          ids.add(tag.id);
                        } else {
                          ids.remove(tag.id);
                        }
                        _current = _current.copyWith(tagIds: ids);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Sort
            _FilterSection(
              title: 'Sort by',
              children: SortOrder.values.map((order) {
                final selected = _current.sortOrder == order;
                return FilterChip(
                  label: Text(_sortLabel(order)),
                  selected: selected,
                  onSelected: (val) {
                    setState(
                      () => _current = _current.copyWith(sortOrder: order),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _current = const LibraryFilter());
                    },
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_current);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(EntryStatus status) => switch (status) {
    EntryStatus.newEntry => 'New',
    EntryStatus.learning => 'Learning',
    EntryStatus.reviewing => 'Reviewing',
    EntryStatus.mastered => 'Mastered',
    EntryStatus.due => 'Due',
  };

  static String _sortLabel(SortOrder order) => switch (order) {
    SortOrder.newest => 'Newest first',
    SortOrder.oldest => 'Oldest first',
    SortOrder.alpha => 'A → Z',
    SortOrder.dueFirst => 'Due first',
    SortOrder.mostReviewed => 'Most reviewed',
  };
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF657069),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

TextDirection _textDirection(VocabularyLanguage language) {
  return language.isRtl ? TextDirection.rtl : TextDirection.ltr;
}

class _CaptureStep extends StatelessWidget {
  const _CaptureStep({required this.step, required this.text});

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF356859),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }
}
