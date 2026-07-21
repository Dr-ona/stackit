import 'package:flutter/material.dart';

import '../../data/text_analyzer.dart';
import '../../models/capture_payload.dart';
import '../../models/dictionary_result.dart';
import '../../models/language_pair.dart';
import '../../l10n/app_localizations.dart';
import 'language_pair_sheet.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_sense_list.dart';

enum CaptureResult { saved, viewExisting }

class CapturePreviewSheet extends StatefulWidget {
  const CapturePreviewSheet({
    super.key,
    required this.capture,
    required this.controller,
  });

  final CapturePayload capture;
  final VocabularyController controller;

  @override
  State<CapturePreviewSheet> createState() => _CapturePreviewSheetState();
}

class _CapturePreviewSheetState extends State<CapturePreviewSheet> {
  late final Future<void> _preparation;
  late LanguagePair _pair;
  late Future<DictionaryResult?> _result;
  late bool _routeAvailable;
  bool _saving = false;
  bool _discovering = false;
  bool _geminiLookup = false;
  final Set<String> _selectedSenseIds = {};

  @override
  void initState() {
    super.initState();
    _preparation = _prepare();
  }

  Future<void> _prepare() async {
    final automaticPair = await widget.controller.resolveCaptureLanguagePair(
      widget.capture.text,
    );
    _routeAvailable = automaticPair != null;
    _pair = automaticPair ?? widget.controller.languagePair;
    _result = _routeAvailable
        ? _lookupWithGeminiFallback(widget.capture.text, _pair)
        : Future.value(null);
  }

  Future<DictionaryResult?> _lookupWithGeminiFallback(
    String text,
    LanguagePair pair,
  ) async {
    final result = await widget.controller.lookup(text, pair: pair);
    if (result == null && mounted) {
      setState(() => _geminiLookup = true);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            18,
            24,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FutureBuilder<void>(
            future: _preparation,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return FutureBuilder<DictionaryResult?>(
                future: _result,
                builder: (context, resultSnapshot) {
                  if (resultSnapshot.connectionState != ConnectionState.done) {
                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            if (_geminiLookup) ...[
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.aiLookupInProgress,
                                style: const TextStyle(
                                  color: Color(0xFF657069),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  if (resultSnapshot.hasError) {
                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: Color(0xFF657069),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.lookupFailed,
                              style: const TextStyle(color: Color(0xFF657069)),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  _result = widget.controller.lookup(
                                    widget.capture.text,
                                    pair: _pair,
                                  );
                                });
                              },
                              child: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final resultData = resultSnapshot.data;
                  if (_selectedSenseIds.isEmpty &&
                      resultData != null &&
                      resultData.senses.length > 1) {
                    for (final s in resultData.senses) {
                      _selectedSenseIds.add(s.id);
                    }
                  }
                  return _PreviewContent(
                    capture: widget.capture,
                    result: resultSnapshot.data,
                    pair: _pair,
                    controller: widget.controller,
                    routeAvailable: _routeAvailable,
                    saving: _saving,
                    discovering: _discovering,
                    selectedSenseIds: _selectedSenseIds,
                    onSave: () => _save(resultSnapshot.data),
                    onChoosePair: _choosePair,
                    onSenseToggled: (senseId, selected) {
                      setState(() {
                        if (selected) {
                          _selectedSenseIds.add(senseId);
                        } else {
                          _selectedSenseIds.remove(senseId);
                        }
                      });
                    },
                    onDiscoverMeanings: () =>
                        _discoverAllMeanings(resultSnapshot.data),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _changePair(LanguagePair pair) {
    setState(() {
      _pair = pair;
      _routeAvailable = true;
      _result = widget.controller.lookup(widget.capture.text, pair: pair);
    });
  }

  Future<void> _choosePair() async {
    final selected = await pickLanguagePair(context, current: _pair);
    if (selected != null && selected != _pair) _changePair(selected);
  }

  Future<void> _discoverAllMeanings(DictionaryResult? offlineResult) async {
    setState(() => _discovering = true);
    try {
      final enriched = await widget.controller.discoverAllMeanings(
        widget.capture.text,
        pair: _pair,
        offlineResult: offlineResult,
        context: widget.capture.context,
      );
      if (!mounted) return;
      setState(() => _result = Future.value(enriched));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.meaningDiscoveryFailed)),
      );
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  Future<void> _save(DictionaryResult? result) async {
    setState(() => _saving = true);
    try {
      final filtered = _filterResult(result);
      await widget.controller.save(widget.capture, filtered, pair: _pair);
      if (!mounted) return;
      Navigator.pop(context, CaptureResult.saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.wordSaveFailed)));
      setState(() => _saving = false);
    }
  }

  DictionaryResult? _filterResult(DictionaryResult? result) {
    if (result == null || _selectedSenseIds.isEmpty) return result;
    final filtered = result.senses
        .where((s) => _selectedSenseIds.contains(s.id))
        .toList();
    if (filtered.isEmpty) return result;
    return DictionaryResult.withSenses(
      sourceText: result.sourceText,
      senses: filtered,
      sourceLanguage: result.sourceLanguage,
      targetLanguage: result.targetLanguage,
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.capture,
    required this.result,
    required this.pair,
    required this.controller,
    required this.routeAvailable,
    required this.saving,
    required this.discovering,
    required this.selectedSenseIds,
    required this.onSave,
    required this.onChoosePair,
    required this.onSenseToggled,
    required this.onDiscoverMeanings,
  });

  final CapturePayload capture;
  final DictionaryResult? result;
  final LanguagePair pair;
  final VocabularyController controller;
  final bool routeAvailable;
  final bool saving;
  final bool discovering;
  final Set<String> selectedSenseIds;
  final VoidCallback onSave;
  final VoidCallback onChoosePair;
  final void Function(String senseId, bool selected) onSenseToggled;
  final VoidCallback onDiscoverMeanings;

  @override
  Widget build(BuildContext context) {
    final alreadySaved = controller.contains(capture.text, pair: pair);
    return Column(
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
        const SizedBox(height: 22),
        if (routeAvailable) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3ECE6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.detectedRoute(pair.label),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: discovering ? null : onChoosePair,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(
              '${pair.source.nativeLabel} → ${pair.target.nativeLabel}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!routeAvailable) ...[
          Text(
            context.l10n.unavailableRoute(
              '${LanguagePair.detectSourceLanguage(capture.text)?.label ?? '?'} → ${controller.preferredTargetLanguage.label}',
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                capture.text,
                textDirection: pair.source.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _TextUnitBadge(text: capture.text),
            IconButton.filledTonal(
              tooltip: context.l10n.pronounce,
              onPressed: () => controller.speak(capture.text, pair.source),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (result != null) ...[
          VocabularySenseList(
            senses: result!.senses,
            sourceText: capture.text,
            sourceLanguage: pair.source,
            targetLanguage: pair.target,
            groupByPartOfSpeech: VocabularySenseList.shouldGroup(
              result!.senses,
            ),
            trailingBuilder: result!.senses.length > 1
                ? (context, sense) {
                    final isSelected = selectedSenseIds.contains(sense.id);
                    return Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          onSenseToggled(sense.id, value ?? false),
                    );
                  }
                : null,
          ),
        ] else ...[
          Text(
            context.l10n.missingOfflineMeaning,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.maySaveMissing),
        ],
        if (controller.canDiscoverMeanings && routeAvailable) ...[
          const SizedBox(height: 18),
          Text(
            context.l10n.findAllMeaningsDescription,
            style: const TextStyle(color: Color(0xFF657069), height: 1.4),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: discovering ? null : onDiscoverMeanings,
              icon: discovering
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                discovering
                    ? context.l10n.findingAllMeanings
                    : context.l10n.findAllMeanings,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (alreadySaved) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              context.l10n.alreadyInLibrary,
              style: const TextStyle(
                color: Color(0xFF4A5249),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, CaptureResult.viewExisting),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(context.l10n.viewExisting),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: !routeAvailable || saving || discovering
                  ? null
                  : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(context.l10n.saveForReview),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.continueReading),
          ),
        ),
      ],
    );
  }
}

class _TextUnitBadge extends StatelessWidget {
  const _TextUnitBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final unit = TextAnalyzer.classify(text);
    final count = TextAnalyzer.wordCount(text);
    final label = unit == TextUnit.word ? 'Word' : '$count words';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: unit == TextUnit.word
            ? const Color(0xFFD4EDDA)
            : const Color(0xFFD1ECF1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: unit == TextUnit.word
              ? const Color(0xFF155724)
              : const Color(0xFF0C5460),
        ),
      ),
    );
  }
}
