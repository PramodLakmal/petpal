import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class FirebaseServices {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();

  Future<String?> signInWithGoogle(BuildContext context) async {
    try {
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      
      // Check if the sign-in was canceled
      if (googleSignInAccount == null) {
        return 'Sign-in canceled by user';
      }
      
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
          
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      
      // Sign in to Firebase with the credentials
      await auth.signInWithCredential(authCredential);
      return null; // Return null on successful sign-in
    } on FirebaseAuthException catch (e) {
      return e.message; // Return the FirebaseAuth error message
    } catch (e) {
      return 'An unknown error occurred'; // Catch any other errors
    }
  }

  Future<void> googleSignOut() async {
    await googleSignIn.signOut();
    await auth.signOut(); // Sign out from Firebase as well
  }
}
