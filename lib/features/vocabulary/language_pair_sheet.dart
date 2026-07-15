import 'package:flutter/material.dart';

import '../../models/language_pair.dart';
import 'vocabulary_controller.dart';

Future<void> showLanguagePairSheet(
  BuildContext context,
  VocabularyController controller, {
  bool requiredSelection = false,
}) async {
  final selected = await showModalBottomSheet<LanguagePair>(
    context: context,
    isScrollControlled: true,
    isDismissible: !requiredSelection,
    enableDrag: !requiredSelection,
    backgroundColor: const Color(0xFFFFFCF5),
    builder: (context) => PopScope(
      canPop: !requiredSelection,
      child: _LanguagePairSheet(current: controller.languagePair),
    ),
  );
  if (selected != null) await controller.setLanguagePair(selected);
}

class _LanguagePairSheet extends StatelessWidget {
  const _LanguagePairSheet({required this.current});

  final LanguagePair current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
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
            const SizedBox(height: 24),
            Text(
              'Choose your language direction',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'The first language is the text you highlight. The second is the language Stackit translates it into.',
              style: TextStyle(color: Color(0xFF657069), height: 1.45),
            ),
            const SizedBox(height: 20),
            for (final pair in LanguagePair.supported) ...[
              _PairOption(
                pair: pair,
                selected: pair == current,
                onTap: () => Navigator.pop(context, pair),
              ),
              if (pair != LanguagePair.supported.last)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _PairOption extends StatelessWidget {
  const _PairOption({
    required this.pair,
    required this.selected,
    required this.onTap,
  });

  final LanguagePair pair;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE3ECE6) : const Color(0xFFF2F0E9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pair.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                color: const Color(0xFF356859),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
