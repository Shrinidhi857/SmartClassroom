import 'package:flutter/material.dart';
import 'package:sihapp/Nearby/Nearbyhandler.dart';
import 'package:sihapp/pages/DownloadPage.dart';
import 'package:sihapp/pages/JoinClassRoomPage.dart';
import 'package:sihapp/pages/NearbyReceive.dart';
import 'package:sihapp/pages/NearbySend.dart';
import 'package:sihapp/pages/NearbyViewPage.dart';
import 'package:sihapp/pages/NewClassroomPage.dart';
import 'package:sihapp/pages/ForgetPasswordPage.dart';
import 'package:sihapp/pages/HomePage.dart';
import 'package:sihapp/pages/ProfilePage.dart';
import 'package:sihapp/pages/SplashPage.dart';
import 'Theme/darkmode.dart';
import 'Theme/lightmode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padhaai',
      theme:lightMode,
      darkTheme: darkMode,
      home:  SplashPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) =>  HomePage(),
        '/profile': (context) =>  ProfilePage(),
        '/forgotpassword': (context) =>  ForgotPage(),
        '/classroom': (context) =>NewClassroomPage() ,
        '/newclassroom': (context) =>   ClassroomPage(),
        '/downloading':(context)=> DownloadPage(),
        '/nearbypage':(context)=>NearbyviewPage(),
        '/nearbysend':(context)=>NearbysendPage(),
        '/nearbyreceive':(context)=>NearbyreceivePage()

      },
    );
  }
}
