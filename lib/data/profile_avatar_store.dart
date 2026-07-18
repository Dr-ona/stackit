import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

const maxProfileAvatarBytes = 2 * 1024 * 1024;

abstract interface class ProfileAvatarStore {
  String pathForUser(String userId);

  Future<Uint8List?> loadAvatar(String userId);

  Future<String> uploadAvatar(String userId, Uint8List bytes);

  Future<void> deleteAvatar(String userId);
}

class FirebaseProfileAvatarStore implements ProfileAvatarStore {
  FirebaseProfileAvatarStore({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instanceFor(app: Firebase.app());

  final FirebaseStorage _storage;

  @override
  String pathForUser(String userId) => 'users/$userId/profile/avatar';

  @override
  Future<Uint8List?> loadAvatar(String userId) async {
    try {
      final data = await _storage
          .ref(pathForUser(userId))
          .getData(maxProfileAvatarBytes);
      return data == null || data.isEmpty ? null : data;
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return null;
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    final contentType = profileAvatarContentType(bytes);
    if (bytes.isEmpty || bytes.lengthInBytes > maxProfileAvatarBytes) {
      throw const ProfileAvatarException('Choose an image smaller than 2 MB.');
    }
    if (contentType == null) {
      throw const ProfileAvatarException('Choose a JPEG, PNG, or WebP image.');
    }

    final reference = _storage.ref(pathForUser(userId));
    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        cacheControl: 'private, max-age=3600',
      ),
    );
    return reference.fullPath;
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      await _storage.ref(pathForUser(userId)).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}

String? profileAvatarContentType(Uint8List bytes) {
  if (bytes.lengthInBytes >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.lengthInBytes >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.lengthInBytes >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

class ProfileAvatarException implements Exception {
  const ProfileAvatarException(this.message);

  final String message;

  @override
  String toString() => message;
}
