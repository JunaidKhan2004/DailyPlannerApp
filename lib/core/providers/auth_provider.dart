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
  bool initialEmitHandled = false;

  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    final prevUser = previous?.valueOrNull;
    final nextUser = next.valueOrNull;

    if (!initialEmitHandled) {
      initialEmitHandled = true;
      // First emit — user already logged in from previous session
      if (nextUser != null) {
        FirestoreService.syncOnLogin();
      }
      return;
    }

    // Subsequent emits — fresh login (was logged out, now logged in)
    if (prevUser == null && nextUser != null) {
      FirestoreService.syncOnLogin();
    }
  });
});
