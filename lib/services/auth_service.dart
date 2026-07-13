import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// IMPORTANT - replace this placeholder with your Firebase project's
/// "Web client ID". Find it at:
/// Firebase Console -> Authentication -> Sign-in method -> Google ->
/// (after enabling it) "Web SDK configuration" -> Web client ID.
/// It looks like: 123456789-abc123.apps.googleusercontent.com
const String kGoogleWebClientId = "REPLACE_WITH_YOUR_WEB_CLIENT_ID.apps.googleusercontent.com";

/// Wraps Google Sign-In + Firebase Auth, and the "users" collection in
/// Firestore, which acts as the client registry for the SaaS: every shop
/// that signs in gets one document here, with an `isActive` flag that
/// only the admin (via the Firebase console) can flip to true/false.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) return;
    await _googleSignIn.initialize(serverClientId: kGoogleWebClientId);
    _googleSignInReady = true;
  }

  /// Signs the user in with their Google account and links it to Firebase.
  /// Returns the signed-in Firebase user, or null if they cancelled.
  Future<User?> signInWithGoogle() async {
    await _ensureGoogleSignInReady();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception("Is device par Google Sign-In supported nahi hai.");
    }

    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication auth = account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception("Google se login token nahi mila. Dubara koshish karein.");
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Makes sure a Firestore doc exists for this user (creates one, locked
  /// as inactive, on first login). Returns whether the account is active.
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

  /// Re-checks activation status for an already signed-in user (used on
  /// cold app start, and on the "Check Again" button in Pending Approval).
  Future<bool> checkActiveStatus(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return (doc.data()?['isActive'] as bool?) ?? false;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore - not critical if this side fails
    }
    await _auth.signOut();
  }
}
