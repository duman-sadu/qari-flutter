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

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static Future<({User? user, String? error})> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

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
      return (user: null, error: e.toString());
    }
  }

  static Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
