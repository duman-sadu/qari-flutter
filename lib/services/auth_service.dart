import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  static Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
