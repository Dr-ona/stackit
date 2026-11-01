import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/profile_avatar_store.dart';

void main() {
  test('recognizes supported avatar image signatures', () {
    expect(
      profileAvatarContentType(Uint8List.fromList([0xff, 0xd8, 0xff])),
      'image/jpeg',
    );
    expect(
      profileAvatarContentType(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]),
      ),
      'image/png',
    );
    expect(
      profileAvatarContentType(
        Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
          0x50,
        ]),
      ),
      'image/webp',
    );
  });

  test('rejects unsupported or incomplete avatar data', () {
    expect(profileAvatarContentType(Uint8List(0)), isNull);
    expect(
      profileAvatarContentType(Uint8List.fromList([0x47, 0x49, 0x46])),
      isNull,
    );
  });
}
