import 'package:flutter/material.dart';
import 'package:petpal/user%20registration/homeScreen.dart';
import 'package:petpal/user%20registration/login.dart';
import 'package:petpal/user%20registration/services/authentication.dart';
import 'package:petpal/user%20registration/widget/button.dart';
import 'package:petpal/user%20registration/widget/showSnackbar.dart';
import 'package:petpal/user%20registration/widget/text_field.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;

  void despose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  void signUpUser() async {
    String res = await AuthServices().signUpUser(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text);

    if (res == "Success") {
      setState(() {
        isLoading = true;
      });

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()));
    } else {
      setState(() {
        isLoading = false;
      });

      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: height / 20),
          SizedBox(
            width: double.infinity,
            height: height / 4,
            child: Image.asset("images/catpaw.png"),
          ),
          SizedBox(height: height / 25),
          TextFieldInput(
              hintText: "name",
              icon: Icons.person,
              textEditingController: nameController),
          TextFieldInput(
              hintText: "email",
              icon: Icons.email,
              textEditingController: emailController),
          TextFieldInput(
              hintText: "password",
              icon: Icons.lock,
              textEditingController: passwordController,
              isPass: true),
          SizedBox(height: height / 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFA6650),
              padding: const EdgeInsets.symmetric(horizontal: 50),
              minimumSize: Size(230.51, 68.1),
            ),
            onPressed: signUpUser,
            child: Text("Sign Up",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          SizedBox(height: height / 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account?",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                  child: Text(
                    " Login",
                    style: TextStyle(
                        color: Color(
                          0xFFFA6650,
                        ),
                        fontWeight: FontWeight.bold),
                  ))
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Color(0xFFFA6650),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  "All rights reserved",
                  style: TextStyle(
                      color: Colors.black, fontSize: 14, letterSpacing: 1.2),
                ),
              ),
            ), // Coral orange color
          )
        ],
      )),
    );
  }
}
