import 'package:flutter/material.dart';

import '../../models/capture_payload.dart';
import '../../models/dictionary_result.dart';
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
  late final Future<DictionaryResult?> _result = widget.controller.lookup(
    widget.capture.text,
  );
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
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
              controller: widget.controller,
              saving: _saving,
              onSave: () => _save(snapshot.data),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(DictionaryResult? result) async {
    setState(() => _saving = true);
    await widget.controller.save(widget.capture, result);
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
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  final CapturePayload capture;
  final DictionaryResult? result;
  final VocabularyController controller;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final alreadySaved = controller.contains(capture.text);
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
        Row(
          children: [
            Expanded(
              child: Text(
                capture.text,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Pronounce',
              onPressed: () => controller.speak(capture.text),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (result != null) ...[
          Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                result!.arabic,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF356859),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result!.definition,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          if (result!.example != null) ...[
            const SizedBox(height: 14),
            Text(
              '“${result!.example}”',
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
