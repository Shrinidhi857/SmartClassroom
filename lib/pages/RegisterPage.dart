import 'package:sihapp/components/my_buttons.dart';
import 'package:sihapp/components/my_textfield.dart';
import 'package:flutter/material.dart';



class RegisterPage extends StatefulWidget{

  final void Function()? onTap;
  RegisterPage({
    super.key,
    required this.onTap,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController emailController =TextEditingController();

  TextEditingController passwordController =TextEditingController();

  TextEditingController confirmController =TextEditingController();

  TextEditingController userNameController =TextEditingController();




  String getThemedImage(bool isDarkMode) {
    return isDarkMode ? 'assets/dark/logo.png' : 'assets/light/logo.png';
  }



  @override
  Widget build(BuildContext context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //logo
                Image.asset(
                  getThemedImage(isDarkMode),
                  width: 150,
                  fit: BoxFit.contain, // optional, controls how the image fits
                ),

                SizedBox(height: 25,),

                //email
                MyTextField(
                  hintText: "User Name",
                  obscureText: false,
                  controller: userNameController,
                ),

                SizedBox(height: 25,),

                //email
                MyTextField(
                  hintText: "Email",
                  obscureText: false,
                  controller: emailController,
                ),

                SizedBox(height: 25,),
                //password
                MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: passwordController,
                ),
                SizedBox(height: 25,),
                //password
                MyTextField(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: confirmController,
                ),

                //forgot


                //sign in
                SizedBox(height: 25,),

                MyButtons(
                  text: "Register",
                  onTap: (){
                    Navigator.pushNamed(context, '/home');
                  },
                ),

                //don't  have an account ?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text("Already have an account?"),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text("Login here",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}