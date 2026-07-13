import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String kGoogleWebClientId = "931830069944-us7memhh3e1hfjbts17e1v5r09p9rc1q.apps.googleusercontent.com";

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: kGoogleWebClientId,
  );

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) return null;

    final GoogleSignInAuthentication auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<bool> ensureUserDocAndCheckActive(User user, {String shopNameHint = "Meri Dukaan"}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'shopName': shopNameHint,
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return false;
    }
    return (doc.data()?['isActive'] as bool?) ?? false;
  }

  Future<bool> checkActiveStatus(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return (doc.data()?['isActive'] as bool?) ?? false;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
