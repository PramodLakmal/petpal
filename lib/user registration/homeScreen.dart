import 'package:flutter/material.dart';
import 'package:petpal/user%20registration/login.dart';
import 'package:petpal/user%20registration/services/authentication.dart';
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
                  await AuthServices().signout();
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
