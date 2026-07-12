import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wraps Firebase Phone Auth (OTP login) and the "users" collection in
/// Firestore, which acts as the client registry for the SaaS: every shop
/// that registers gets one document here, with an `isActive` flag that
/// only the admin (via the Firebase console) can flip to true/false.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Starts the OTP flow. Calls [onCodeSent] with a verificationId once
  /// the SMS has been sent, or [onError] if something went wrong.
  /// [onAutoVerified] fires on some Android devices that auto-detect the
  /// SMS code without the user typing it.
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
    required void Function(UserCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final result = await _auth.signInWithCredential(credential);
        onAutoVerified(result);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "OTP bhejne mein masla hua. Number check karein.");
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Verifies the 6-digit code the user typed in.
  Future<User?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
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
        'phone': user.phoneNumber,
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

  Future<void> signOut() => _auth.signOut();
}
