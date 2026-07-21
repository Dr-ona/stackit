import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/collection.dart';
import '../../models/vocabulary_entry.dart';
import 'vocabulary_controller.dart';

class CollectionPickerSheet extends StatefulWidget {
  const CollectionPickerSheet({
    super.key,
    required this.controller,
    required this.entry,
    this.selectOnly = false,
  });

  final VocabularyController controller;
  final VocabularyEntry entry;
  final bool selectOnly;

  @override
  State<CollectionPickerSheet> createState() => _CollectionPickerSheetState();
}

class _CollectionPickerSheetState extends State<CollectionPickerSheet> {
  final _newCollectionController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _newCollectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collections = widget.controller.collections;
    final entryCollectionIds = widget.entry.collectionIds;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          18,
          24,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D0C6),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.addToCollection,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (collections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.l10n.noCollectionsYet,
                  style: const TextStyle(color: Color(0xFF657069)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    final isMember = entryCollectionIds.contains(collection.id);
                    return CheckboxListTile(
                      value: isMember,
                      title: Text(collection.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (selected) async {
                        if (widget.selectOnly) {
                          Navigator.pop(context, collection);
                          return;
                        }
                        if (selected == true) {
                          await widget.controller.addToCollection(
                            widget.entry,
                            collection.id,
                          );
                        } else {
                          await widget.controller.removeFromCollection(
                            widget.entry,
                            collection.id,
                          );
                        }
                        if (mounted) setState(() {});
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: context.l10n.cancel,
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(context.l10n.deleteCollectionOnly),
                              content: Text(
                                context.l10n.deleteCollectionOnlyHint,
                              ),
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
                          if (confirmed == true) {
                            await widget.controller.deleteCollection(
                              collection.id,
                            );
                            if (mounted) setState(() {});
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCollectionController,
                    decoration: InputDecoration(
                      hintText: context.l10n.newCollectionHint,
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _createCollection(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _creating ? null : _createCollection,
                  icon: _creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.done),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCollection() async {
    final name = _newCollectionController.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final collection = await widget.controller.createCollection(name);
      await widget.controller.addToCollection(widget.entry, collection.id);
      _newCollectionController.clear();
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}

Future<Collection?> showCollectionPicker(
  BuildContext context, {
  required VocabularyController controller,
  required VocabularyEntry entry,
  bool selectOnly = false,
}) {
  return showModalBottomSheet<Collection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFCF5),
    builder: (_) => CollectionPickerSheet(
      controller: controller,
      entry: entry,
      selectOnly: selectOnly,
    ),
  );
}
