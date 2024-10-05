import 'package:flutter/material.dart';
import 'package:petpal/user%20registration/SignUp.dart';
import 'package:petpal/user%20registration/homeScreen.dart';
import 'package:petpal/user%20registration/services/authentication.dart';
import 'package:petpal/user%20registration/widget/button.dart';
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
  void despose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUsers() async {
    String res = await AuthServices().loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    if (res == "Success") {
      setState(() {
        isLoading = true;
      });

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
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
          SizedBox(
            width: double.infinity,
            height: height / 2.7,
            child: Image.asset("images/dog.png"),
          ),
          TextFieldInput(
              hintText: "email",
              icon: Icons.email,
              textEditingController: emailController),
          TextFieldInput(
              hintText: "password",
              icon: Icons.lock,
              textEditingController: passwordController,
              isPass: true),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Forgot Password?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          MyButton(onTab: loginUsers, text: "Login"),
          SizedBox(height: height / 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an accout?"),
              GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => SignUp()));
                  },
                  child: Text(
                    "Sign Up",
                    style: TextStyle(color: Colors.blue),
                  ))
            ],
          )
        ],
      )),
    );
  }
}
