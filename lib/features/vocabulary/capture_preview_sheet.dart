import 'package:flutter/material.dart';

import '../../models/capture_payload.dart';
import '../../models/dictionary_result.dart';
import '../../models/language_pair.dart';
import '../../l10n/app_localizations.dart';
import 'language_pair_sheet.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_sense_list.dart';

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
        ? widget.controller.lookup(widget.capture.text, pair: _pair)
        : Future.value(null);
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
            12,
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
                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _PreviewContent(
                    capture: widget.capture,
                    result: resultSnapshot.data,
                    pair: _pair,
                    controller: widget.controller,
                    routeAvailable: _routeAvailable,
                    saving: _saving,
                    discovering: _discovering,
                    onSave: () => _save(resultSnapshot.data),
                    onChoosePair: _choosePair,
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
      await widget.controller.save(widget.capture, result, pair: _pair);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.wordSaveFailed)));
      setState(() => _saving = false);
    }
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
    required this.onSave,
    required this.onChoosePair,
    required this.onDiscoverMeanings,
  });

  final CapturePayload capture;
  final DictionaryResult? result;
  final LanguagePair pair;
  final VocabularyController controller;
  final bool routeAvailable;
  final bool saving;
  final bool discovering;
  final VoidCallback onSave;
  final VoidCallback onChoosePair;
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
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: !routeAvailable || alreadySaved || saving || discovering
                ? null
                : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(alreadySaved ? Icons.check_rounded : Icons.add_rounded),
            label: Text(
              alreadySaved
                  ? context.l10n.alreadySaved
                  : context.l10n.saveForReview,
            ),
          ),
        ),
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
