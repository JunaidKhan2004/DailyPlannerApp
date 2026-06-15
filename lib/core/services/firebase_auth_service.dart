import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../features/tasks/data/models/task_model.dart';

class FirebaseAuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  /// Signs out and clears local Hive data so next user starts fresh.
  static Future<void> signOut() async {
    // Clear local tasks before signing out so another user
    // logging in on the same device sees only their own data.
    final box = Hive.box<TaskModel>(AppConstants.tasksBox);
    await box.clear();

    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
