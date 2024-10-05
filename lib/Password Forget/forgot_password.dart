import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petpal/user%20registration/widget/showSnackbar.dart';

class Forgot_password extends StatefulWidget {
  const Forgot_password({super.key});

  @override
  State<Forgot_password> createState() => _Forgot_passwordState();
}

class _Forgot_passwordState extends State<Forgot_password> {
  TextEditingController emailController = TextEditingController();
  final auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 35),
        child: Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () {
              myDialogBox(context);
            },
            child: Text(
              "Forgot password?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }

  void myDialogBox(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Forgot Your Password",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close))
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter the email",
                        hintText: "egs sadf@gmail.com"),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.blue),
                      onPressed: () async {
                        await auth
                            .sendPasswordResetEmail(email: emailController.text)
                            .then((value) {
                          showSnackBar(context,
                              "We have sent you the reset password link to your email");
                        }).onError((error, stackTrace) {
                          showSnackBar(context, error.toString());
                        });
                        Navigator.pop(context);
                        emailController.clear();
                      },
                      child: Text(
                        "send",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ))
                ],
              ),
            ),
          );
        });
  }
}
