import 'package:sihapp/components/my_buttons.dart';
import 'package:flutter/material.dart';

import '../components/my_textfield.dart';

class ForgotPage extends StatefulWidget {

  ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final TextEditingController emailController = TextEditingController();





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Icon(
                    Icons.person,
                    size: 80,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  const SizedBox(height: 25),

                  Text(
                    "SIH",
                    style: TextStyle(fontSize: 20),
                  ),

                  const SizedBox(height: 25),

                  // Email Field
                  MyTextField(
                    hintText: "Email",
                    obscureText: false,
                    controller: emailController,
                  ),

                  const SizedBox(height: 10),

                  MyButtons(
                    text: "Send Reset Link",
                    onTap: (){},
                  ),

                ]
            ),
          ),
        ),
      ),
    );
  }
}
