import 'package:flutter/material.dart';
import 'package:petpal/Password%20Forget/forgot_password.dart';

import 'package:petpal/user%20registration/SignUp.dart';
import 'package:petpal/user%20registration/homeScreen.dart';
import 'package:petpal/user%20registration/services/authentication.dart';
import 'package:petpal/user%20registration/services/google_auth.dart';
import 'package:petpal/user%20registration/widget/showSnackbar.dart';
import 'package:petpal/user%20registration/widget/text_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUsers() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showSnackBar(context, "Please fill in both fields");
      return;
    }

    setState(() {
      isLoading = true;
    });

    String res = await AuthServices().loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (res == "user") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 30,
              ),
              SizedBox(
                width: double.infinity,
                height: height / 2.7,
                child: Image.asset("images/logo.png"),
              ),
              TextFieldInput(
                hintText: "Email",
                icon: Icons.email,
                textEditingController: emailController,
              ),
              TextFieldInput(
                hintText: "Password",
                icon: Icons.lock,
                textEditingController: passwordController,
                isPass: true,
              ),
              SizedBox(height: 10),
              const Forgot_password(),
              SizedBox(height: height / 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  minimumSize: Size(230.51, 68.1),
                ),
                onPressed: loginUsers,
                child: Text("Login",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              SizedBox(height: height / 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUp()),
                      );
                    },
                    child: const Text(
                      " Sign Up",
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height / 60),
              Row(
                children: [
                  Expanded(child: Container(height: 2, color: Colors.grey)),
                  Padding(
                    padding: const EdgeInsets.all(5),
                  ),
                  const Text("or"),
                  Padding(
                    padding: const EdgeInsets.all(5),
                  ),
                  Expanded(child: Container(height: 2, color: Colors.grey)),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black45, width: 2),
                    ),
                    minimumSize: Size(250, 50),
                  ),onPressed: () async {
  String? result = await FirebaseServices().signInWithGoogle(context);
  
  if (result == null) {
    // If the result is null, sign-in was successful
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } else {
    // Show error message
    showSnackBar(context, result);
  }
},

                
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Image.network(
                          "https://image.similarpng.com/very-thumbnail/2020/06/Logo-google-icon-PNG.png",
                          height: 35,
                           errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error); // Show an error icon if loading fails
  },
                        ),
                      ),
                      const Text(
                        "Continue with Google",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Adjust height
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20),
                color: Colors.orange,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      "All rights reserved",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          letterSpacing: 1.2),
                    ),
                  ),
                ), // Coral orange color
              ),
            ],
          ),
        ),
      ),
    );
  }
}
