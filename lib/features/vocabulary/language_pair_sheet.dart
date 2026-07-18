import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/language_pair.dart';
import 'vocabulary_controller.dart';

Future<void> showTargetLanguageSheet(
  BuildContext context,
  VocabularyController controller, {
  bool requiredSelection = false,
}) async {
  final selected = await pickLanguagePair(
    context,
    current: controller.languagePair,
    requiredSelection: requiredSelection,
  );
  if (selected != null) {
    await controller.setLanguagePair(selected);
  }
}

Future<LanguagePair?> pickLanguagePair(
  BuildContext context, {
  required LanguagePair current,
  bool requiredSelection = false,
}) {
  return showModalBottomSheet<LanguagePair>(
    context: context,
    isScrollControlled: true,
    isDismissible: !requiredSelection,
    enableDrag: !requiredSelection,
    backgroundColor: const Color(0xFFFFFCF5),
    builder: (context) => PopScope(
      canPop: !requiredSelection,
      child: _LanguagePairWheelSheet(current: current),
    ),
  );
}

// Keeps older callers source-compatible while preferences migrate from a
// fixed direction to a preferred target language.
Future<void> showLanguagePairSheet(
  BuildContext context,
  VocabularyController controller, {
  bool requiredSelection = false,
}) => showTargetLanguageSheet(
  context,
  controller,
  requiredSelection: requiredSelection,
);

class _LanguagePairWheelSheet extends StatefulWidget {
  const _LanguagePairWheelSheet({required this.current});

  final LanguagePair current;

  @override
  State<_LanguagePairWheelSheet> createState() =>
      _LanguagePairWheelSheetState();
}

class _LanguagePairWheelSheetState extends State<_LanguagePairWheelSheet> {
  late VocabularyLanguage _source;
  late VocabularyLanguage _target;
  late final FixedExtentScrollController _sourceController;
  late final FixedExtentScrollController _targetController;

  @override
  void initState() {
    super.initState();
    _source = widget.current.source;
    _target = widget.current.target;
    _sourceController = FixedExtentScrollController(
      initialItem: VocabularyLanguage.values.indexOf(_source),
    );
    _targetController = FixedExtentScrollController(
      initialItem: VocabularyLanguage.values.indexOf(_target),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  LanguagePair? get _selectedPair => LanguagePair.route(_source, _target);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              l10n.chooseTranslationRoute,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translationRouteDescription,
              style: const TextStyle(color: Color(0xFF657069), height: 1.45),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _LanguageWheel(
                    label: l10n.fromLanguage,
                    controller: _sourceController,
                    selected: _source,
                    onSelected: (value) => setState(() => _source = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 36, 10, 0),
                  child: Directionality(
                    textDirection: Directionality.of(context),
                    child: const Icon(Icons.arrow_forward_rounded, size: 28),
                  ),
                ),
                Expanded(
                  child: _LanguageWheel(
                    label: l10n.toLanguage,
                    controller: _targetController,
                    selected: _target,
                    onSelected: (value) => setState(() => _target = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _selectedPair == null
                  ? Container(
                      key: const ValueKey('unsupported'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _source == _target
                            ? l10n.chooseDifferentLanguages
                            : l10n.unavailableLanguageRoute(
                                _source.nativeLabel,
                                _target.nativeLabel,
                              ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Text(
                      _selectedPair!.label,
                      key: ValueKey(_selectedPair!.id),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF356859),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedPair == null
                    ? null
                    : () => Navigator.pop(context, _selectedPair),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(l10n.useTranslationRoute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageWheel extends StatelessWidget {
  const _LanguageWheel({
    required this.label,
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final FixedExtentScrollController controller;
  final VocabularyLanguage selected;
  final ValueChanged<VocabularyLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF657069),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 158,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 48,
            diameterRatio: 1.15,
            squeeze: 1.05,
            useMagnifier: true,
            magnification: 1.08,
            selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
              background: const Color(0xFFDDEAE4).withValues(alpha: 0.72),
            ),
            onSelectedItemChanged: (index) =>
                onSelected(VocabularyLanguage.values[index]),
            children: [
              for (final language in VocabularyLanguage.values)
                Center(
                  child: Text(
                    language.nativeLabel,
                    textDirection: language.isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: language == selected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
