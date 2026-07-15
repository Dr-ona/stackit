import 'package:flutter/material.dart';

import '../../models/capture_payload.dart';
import '../../models/dictionary_result.dart';
import '../../models/language_pair.dart';
import 'highlighted_example_text.dart';
import 'translation_meaning_list.dart';
import 'vocabulary_controller.dart';

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
  late final LanguagePair _pair = widget.controller.resolveLanguagePair(
    widget.capture.text,
  );
  late final Future<DictionaryResult?> _result = widget.controller.lookup(
    widget.capture.text,
    pair: _pair,
  );
  bool _saving = false;

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
          child: FutureBuilder<DictionaryResult?>(
            future: _result,
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _PreviewContent(
                capture: widget.capture,
                result: snapshot.data,
                pair: _pair,
                controller: widget.controller,
                saving: _saving,
                onSave: () => _save(snapshot.data),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _save(DictionaryResult? result) async {
    setState(() => _saving = true);
    await widget.controller.save(widget.capture, result, pair: _pair);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${widget.capture.text}” saved for review')),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.capture,
    required this.result,
    required this.pair,
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  final CapturePayload capture;
  final DictionaryResult? result;
  final LanguagePair pair;
  final VocabularyController controller;
  final bool saving;
  final VoidCallback onSave;

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
        if (pair != controller.languagePair) ...[
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
                    'Detected ${pair.source.label} text — using ${pair.label} '
                    'for this capture.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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
              tooltip: 'Pronounce',
              onPressed: () => controller.speak(capture.text, pair.source),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (result != null) ...[
          Text(
            '${pair.target.label} equivalents',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF657069),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TranslationMeaningList(
            translations: result!.translations,
            language: pair.target,
          ),
          const SizedBox(height: 12),
          Text(
            result!.definition,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          if (result!.example != null) ...[
            const SizedBox(height: 14),
            HighlightedExampleText(
              example: result!.example!,
              term: capture.text,
              language: pair.source,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF59655F),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ] else ...[
          Text(
            'Sorry, this meaning is not in the offline dictionary yet.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can still save it and enrich it when you are online.',
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: alreadySaved || saving ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(alreadySaved ? Icons.check_rounded : Icons.add_rounded),
            label: Text(alreadySaved ? 'Already saved' : 'Save for review'),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue reading'),
          ),
        ),
      ],
    );
  }
}
