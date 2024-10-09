import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/admin%20side/adminScreens/Usermanagement.dart';
import 'package:petpal/admin%20side/admin_dashboard.dart';
import 'package:petpal/admin%20side/admin_login.dart';
import 'package:petpal/user%20registration/homeScreen.dart';
import 'package:petpal/user%20registration/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBTf6DfwCW4ioY0SoreJqfsBxUDkiMd8Yc",
          authDomain: "petpal-8005a.firebaseapp.com",
          projectId: "petpal-8005a",
          storageBucket: "petpal-8005a.appspot.com",
          messagingSenderId: "64840973155",
          appId: "1:64840973155:android:552b80c9ec9db76c2eb156",
          measurementId: "G-Z34LMFDZ28",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    runApp(const MyApp());
  } catch (e) {
    // Handle initialization errors here
    print('Firebase initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (kIsWeb) {
          // Web: Check if the user is an admin or not
          if (snapshot.hasData) {
            User? user = snapshot.data;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: Scaffold(
                        body: Center(child: CircularProgressIndicator())),
                  );
                }

                if (userSnapshot.hasData) {
                  bool isAdmin = userSnapshot.data!['isAdmin'] ?? false;
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: isAdmin ? const Usermanagement() : const Login(),
                  );
                } else {
                  return const MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: AdminLogin(),
                  );
                }
              },
            );
          } else {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: AdminLogin(),
            );
          }
        } else {
          // Mobile: Redirect to the user login screen
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: snapshot.hasData ? const HomeScreen() : const Login(),
          );
        }
      },
    );
  }
}
