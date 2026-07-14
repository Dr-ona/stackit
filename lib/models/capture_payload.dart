class CapturePayload {
  const CapturePayload({required this.text, this.source});

  final String text;
  final String? source;

  factory CapturePayload.fromMap(Map<Object?, Object?> map) {
    return CapturePayload(
      text: (map['text'] as String? ?? '').trim(),
      source: map['source'] as String?,
    );
  }
}
