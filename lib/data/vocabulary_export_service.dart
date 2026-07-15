import 'dart:convert';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

class VocabularyExportService {
  const VocabularyExportService();

  Future<void> shareJson(String json, {Rect? sharePositionOrigin}) async {
    final stamp = DateTime.now().toUtc().toIso8601String().split('T').first;
    final file = XFile.fromData(
      utf8.encode(json),
      mimeType: 'application/json',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: ['stackit-vocabulary-$stamp.json'],
        title: 'Stackit vocabulary export',
        subject: 'My Stackit vocabulary',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
