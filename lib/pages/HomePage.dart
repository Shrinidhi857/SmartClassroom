import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sihapp/Canvas/Canvas.dart';
import 'package:sihapp/components/WeblmPlayer.dart';
import 'package:sihapp/components/homeCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {


  void onTapNewRoom() async{Navigator.pushNamed(context, '/newclassroom');}
  void onTapRecorded() async{}
  void onTapJoinRoom() async{Navigator.pushNamed(context,  '/classroom');}

  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title:Text(
          "SIH",
          style: GoogleFonts.roboto(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.w900,
            fontSize: 25,
          ),
        )
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: screenWidth,
                  height: 250, // adjust as needed
                  child: Lottie.asset(
                    'assets/STUDENT.json',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                HomeCard(
                  onTapRecorded: onTapRecorded,
                  onTapNewRoom: onTapNewRoom,
                  onTapJoinRoom: onTapJoinRoom,
                ),
              ],
            ),
          ),

        ],
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                DrawerHeader(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                Text(
                  "User name",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),



                SizedBox(height: 30),
                GestureDetector(
                  onTap: (){
                  Navigator.pushNamed(context, '/profile');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_2, size: 20, color: Theme.of(context).colorScheme.inversePrimary),
                      SizedBox(width: 8),
                      Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.inversePrimary)),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                GestureDetector(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_box, size: 20, color: Theme.of(context).colorScheme.inversePrimary),
                      SizedBox(width: 8),
                      Text("Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.inversePrimary)),
                    ],
                  ),
                ),

                SizedBox(height: 30),
                GestureDetector(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, size: 20, color: Theme.of(context).colorScheme.inversePrimary),
                      SizedBox(width: 8),
                      Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.inversePrimary)),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                GestureDetector(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20, color: Theme.of(context).colorScheme.inversePrimary),
                      SizedBox(width: 8),
                      Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color:Theme.of(context).colorScheme.inversePrimary)),
                    ],
                  ),
                ),
              ],

            ),
          ],
        ),
      ),


    );
  }
}
