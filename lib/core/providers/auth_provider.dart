import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuthService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Watches auth state — triggers two-way Firestore↔Hive sync on login.
/// Must be initialized once in app.dart via ref.watch/listen.
final authSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    final prevUser = previous?.valueOrNull;
    final nextUser = next.valueOrNull;

    // Trigger sync only when user freshly logs in (was null, now non-null)
    if (prevUser == null && nextUser != null) {
      FirestoreService.syncOnLogin();
    }
  });
});
