class CapturePayload {
  const CapturePayload({
    required this.text,
    this.source,
    this.context,
    this.sourceAppName,
    this.sourceUrl,
    this.timestamp,
  });

  const CapturePayload.manual({required this.text})
    : source = manualSource,
      context = null,
      sourceAppName = null,
      sourceUrl = null,
      timestamp = null;

  static const manualSource = 'manual';

  final String text;
  final String? source;
  final String? context;
  final String? sourceAppName;
  final String? sourceUrl;
  final DateTime? timestamp;

  bool get isManual => source == manualSource;

  factory CapturePayload.fromMap(Map<Object?, Object?> map) {
    return CapturePayload(
      text: (map['text'] as String? ?? '').trim(),
      source: map['source'] as String?,
      context: map['context'] as String?,
      sourceAppName: map['sourceAppName'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is String) {
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }
}
