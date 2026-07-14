import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../models/capture_payload.dart';
import '../../models/vocabulary_entry.dart';
import '../review/review_page.dart';
import 'capture_preview_sheet.dart';
import 'vocabulary_controller.dart';

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
    if (_sheetOpen || widget.controller.pendingCapture == null) return;
    final capture = widget.controller.takePendingCapture();
    if (capture == null) return;
    _sheetOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCapture(capture));
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
      _Inbox(controller: widget.controller, authService: widget.authService),
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
  const _Inbox({required this.controller, required this.authService});

  final VocabularyController controller;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
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
                    '${controller.entries.length} saved',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: authService.signOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
        ),
        if (!controller.isReady)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.entries.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyInbox())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: controller.entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _WordCard(
                entry: controller.entries[index],
                controller: controller,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

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
            child: const Icon(Icons.text_fields_rounded, size: 38),
          ),
          const SizedBox(height: 24),
          Text(
            'Meet a word worth keeping?',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Highlight English text in another app, then choose “Stackit” to understand and save it.',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.term,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          entry.arabic,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF356859),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pronounce',
                onPressed: () => controller.speak(entry.term),
                icon: const Icon(Icons.volume_up_outlined),
              ),
            ],
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
              entry.term.toLowerCase().contains(normalized) ||
              entry.arabic.contains(query.trim()),
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
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                        title: Text(
                          entry.term,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          entry.arabic,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
