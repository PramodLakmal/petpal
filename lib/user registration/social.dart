import 'package:flutter/material.dart';

class Social extends StatefulWidget {
  const Social({super.key});

  @override
  State<Social> createState() => _SocialState();
}

class _SocialState extends State<Social> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text("Social"),
      ),
    );
  }
}
