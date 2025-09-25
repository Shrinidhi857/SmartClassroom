import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sihapp/components/ClassExport.dart';
import 'package:sihapp/components/CloudDownload.dart';
import 'package:sihapp/components/NearByDownload.dart';


class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _HomePageState();
}

class _HomePageState extends State<DownloadPage> with SingleTickerProviderStateMixin {
  void onTapNearby() async{}
  void onTapCloud() async{}
  void onTapExport() async{}


  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
          title:Text(
            "Download",
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
                /*SizedBox(
                  width: screenWidth,
                  height: 250, // adjust as needed
                  child: Lottie.asset(
                    'assets/downloading.json',
                    fit: BoxFit.cover,
                    repeat: true,
                    animate: true,
                  ),
                ),*/
                Nearbydownload(onTapNearbyHandling: onTapNearby,),
                Clouddownload(onTapCloudHandling: onTapCloud,),
                Classexport(onTapExportHandling: onTapExport,),

                const SizedBox(height: 16),
              ],
            ),
          ),

        ],
      ),


    );
  }
}
