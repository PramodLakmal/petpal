import 'package:flutter/material.dart';
import 'package:petpal/user%20registration/login.dart';
import 'package:petpal/user%20registration/services/google_auth.dart';
import 'package:petpal/user%20registration/widget/button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Text("home"),
            MyButton(
                onTab: () async {
                  await FirebaseServices().googleSignOut();
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => Login()));
                },
                text: "Logout")
          ],
        ),
      ),
    );
  }
}
