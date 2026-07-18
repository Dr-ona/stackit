class CapturePayload {
  const CapturePayload({required this.text, this.source});

  const CapturePayload.manual({required this.text}) : source = manualSource;

  static const manualSource = 'manual';

  final String text;
  final String? source;

  bool get isManual => source == manualSource;

  factory CapturePayload.fromMap(Map<Object?, Object?> map) {
    return CapturePayload(
      text: (map['text'] as String? ?? '').trim(),
      source: map['source'] as String?,
    );
  }
}
