import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class Classexport extends StatelessWidget {
  final void Function()? onTapExportHandling;


  const Classexport({
    Key? key,
    this.onTapExportHandling,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using a Card for the main container to get a nice shadow and rounded corners.
    return Card(
      margin: EdgeInsets.only(left: 5, right: 5,top: 5),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Theme
          .of(context)
          .colorScheme
          .secondary,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                      height:120, // adjust as needed
                      child: Lottie.asset(
                        'assets/classcontent.json',
                        fit: BoxFit.cover,
                        repeat: true,
                        animate: true,
                      )),
                  Text(
                    "Export Class content",
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}