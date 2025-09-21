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
                Image.asset(getThemedImage(isDarkMode),scale:5,),
                const SizedBox(height: 25,),

                //app name
                Text(
                  "Playmate",
                  style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),
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
                SizedBox(height: 15,),

                ElevatedButton(
                  onPressed: (){},
                  child:
                  SizedBox(
                    height: 45,
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 40,width:40,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,  // Background color
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/images/google.png',), // Local image
                              )
                          ),
                        ),
                        SizedBox(width: 10,),
                        Text("Signin with Google",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}