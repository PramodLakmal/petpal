import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String> signUpUser(
      {required String email,
      required String password,
      required String name}) async {
    String res = "Some error occured";
    try {
      if (email.isNotEmpty || password.isNotEmpty || name.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

            print(credential.user!.uid);

        await _firebaseFirestore
            .collection("users")
            .doc(credential.user!.uid)
            .set({"name": name, "email": email, "uid": credential.user!.uid, "isAdmin": false, "isUser": true});
        res = "Success";
      }
    } catch (e) {
      print(e.toString());
    }
    return res;
  }

  Future<String> loginUser(
      {required String email, required String password}) async {
    String res = "Some error Occured";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
       UserCredential cred= await _auth.signInWithEmailAndPassword(
            email: email, password: password);

            DocumentSnapshot userSnapshot = await _firebaseFirestore.collection("users").doc(cred.user!.uid).get();

       bool isAdmin = userSnapshot['isAdmin'] ?? false;     
      if (isAdmin) {
        // Redirect to admin dashboard
        res = "admin";
      } else {
        // Redirect to regular user home screen
        res = "user";
      }
      
      } else {
        res = "please enter all the field";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  Future<void> signout() async {
    await _auth.signOut();
  }
}
