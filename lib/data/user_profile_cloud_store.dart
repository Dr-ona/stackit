import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/user_profile.dart';

abstract interface class UserProfileCloudStore {
  Future<UserProfile?> loadProfile(String userId);

  Future<void> saveProfile(String userId, UserProfile profile);

  Future<void> deleteProfile(String userId);
}

class FirestoreUserProfileCloudStore implements UserProfileCloudStore {
  FirestoreUserProfileCloudStore({FirebaseFirestore? firestore})
    : _firestore =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'stackit',
          );

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('main');
  }

  @override
  Future<UserProfile?> loadProfile(String userId) async {
    final snapshot = await _profile(userId).get();
    final data = snapshot.data();
    return data == null ? null : _fromFirestore(data);
  }

  @override
  Future<void> saveProfile(String userId, UserProfile profile) {
    return _profile(
      userId,
    ).set(_toFirestore(profile), SetOptions(merge: false));
  }

  @override
  Future<void> deleteProfile(String userId) {
    return _profile(userId).delete();
  }

  Map<String, dynamic> _toFirestore(UserProfile profile) {
    final json = profile.normalized().toJson();
    return {
      ...json,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': Timestamp.fromDate(profile.updatedAt),
    };
  }

  UserProfile _fromFirestore(Map<String, dynamic> data) {
    return UserProfile.fromJson({
      ...data,
      'createdAt': _date(data['createdAt'])?.toIso8601String(),
      'updatedAt': _date(data['updatedAt'])?.toIso8601String(),
    });
  }

  DateTime? _date(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
