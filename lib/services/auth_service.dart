import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'api_service.dart';

class AuthService {
  static Future<({User? user, String? error})> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(
        clientId: '302075601219-p3fi529p33nn157e5kq7p8kf01q46q2o.apps.googleusercontent.com',
        serverClientId: '302075601219-24iu1qmgbj6fuo3k8t1qn0bemhjvs1eu.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        return (user: null, error: null); // user cancelled
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        return (user: null, error: 'idToken алынбады. SHA-1 тіркелгенін тексеріңіз.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);

      // Register / sync user in PostgreSQL backend (fire-and-forget)
      ApiService.loginToBackend();

      return (user: result.user, error: null);
    } on FirebaseAuthException catch (e) {
      return (user: null, error: e.message ?? e.code);
    } catch (e) {
      return (user: null, error: e.toString());
    }
  }

  static Future<({User? user, String? error})> signInWithApple() async {
    try {
      final oauthCredential = await _appleCredential();
      final result =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      ApiService.loginToBackend();
      return (user: result.user, error: null);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return (user: null, error: null);
      }
      return (user: null, error: e.message);
    } on FirebaseAuthException catch (e) {
      return (user: null, error: e.message ?? e.code);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('Cancel')) {
        return (user: null, error: null);
      }
      return (user: null, error: msg);
    }
  }

  // Native Sign in with Apple: returns a Firebase credential built from the
  // Apple ID credential with a nonce. Used for both sign-in and re-auth.
  static Future<OAuthCredential> _appleCredential() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    return OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
  }

  static Future<AuthCredential?> _googleCredential() async {
    final googleUser = await GoogleSignIn(
      clientId: '302075601219-p3fi529p33nn157e5kq7p8kf01q46q2o.apps.googleusercontent.com',
      serverClientId: '302075601219-24iu1qmgbj6fuo3k8t1qn0bemhjvs1eu.apps.googleusercontent.com',
    ).signIn();
    if (googleUser == null) return null; // cancelled
    final googleAuth = await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Permanently deletes the user's account: backend data, Firebase Auth user,
  /// and signs out. Re-authenticates when Firebase requires a recent login.
  static Future<({bool ok, String? error})> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return (ok: false, error: 'no-user');
    try {
      // Best-effort backend cleanup while the token is still valid.
      await ApiService.deleteMyAccount();
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        await _reauthenticate(user);
        await user.delete();
      }
      await GoogleSignIn().signOut();
      return (ok: true, error: null);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return (ok: false, error: null);
      }
      return (ok: false, error: e.message);
    } on FirebaseAuthException catch (e) {
      return (ok: false, error: e.message ?? e.code);
    } catch (e) {
      return (ok: false, error: e.toString());
    }
  }

  static Future<void> _reauthenticate(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toSet();
    if (providers.contains('apple.com')) {
      await user.reauthenticateWithCredential(await _appleCredential());
    } else if (providers.contains('google.com')) {
      final cred = await _googleCredential();
      if (cred == null) throw FirebaseAuthException(code: 'user-cancelled');
      await user.reauthenticateWithCredential(cred);
    }
  }

  static Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
