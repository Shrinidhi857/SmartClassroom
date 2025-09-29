import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../Nearby/NearbyAuto.dart';

class NearbyviewPage extends StatefulWidget {
  const NearbyviewPage({super.key});

  @override
  State<NearbyviewPage> createState() => _NearbyviewPageState();
}

class _NearbyviewPageState extends State<NearbyviewPage> {
  bool _autoConnect = false;

  NearbyAutoManager? _manager;

  void _toggleAutoConnect(bool val) {
    setState(() => _autoConnect = val);

    if (val) {
      _manager = NearbyAutoManager(
        userName: "User_${DateTime.now().millisecondsSinceEpoch}",
        docs: ["doc1.pdf", "doc2.txt"], // TODO: replace with your picked files
        onPeerUpdated: (peers) {
          debugPrint("Peers updated: $peers");
          // here you can update UI with available docs from others
        },
      );
      _manager!.start();
    } else {
      _manager?.stop();
      _manager = null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          "Nearby Share",
          style: GoogleFonts.roboto(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.w900,
            fontSize: 25,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: screenWidth,
              height: 300,
              child: Lottie.asset(
                'assets/Share.json',
                fit: BoxFit.cover,
              ),
            ),

            // Manual Send
            _FeatureButton(
              title: "Manual Send",
              onTap: () {
               Navigator.pushNamed(context, '/nearbysend');
              },
            ),

            // Manual Receive
            _FeatureButton(
              title: "Manual Receive",
              onTap: () {
                Navigator.pushNamed(context, '/nearbyreceive');
              }
            ),

            // Auto Connect (with switch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Auto Connect",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color:
                          Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      Switch(
                        value: _autoConnect,
                        onChanged: (val) {
                          setState(() {
                            _autoConnect = val;
                          });
                          debugPrint("Auto connect: $val");
                        },
                        activeThumbColor: Colors.green,       // Thumb color when ON
                        activeTrackColor: Colors.green.shade200, // Track color when ON
                        inactiveThumbColor: Colors.red,  // Thumb color when OFF
                        inactiveTrackColor: Colors.red.shade200, // Track color when OFF
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable feature button (full-width non-expandable)
class _FeatureButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
