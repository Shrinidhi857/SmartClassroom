import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sihapp/components/homeCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mock class list
  final List<Map<String, dynamic>> classList = [
    {"className": "Math Lecture", "creatorName": "Prof. Sharma", "classType": "Live"},
    {"className": "AI Workshop", "creatorName": "Dr. Ramesh", "classType": "Planned"},
    {"className": "Physics Revision", "creatorName": "Prof. Mehta", "classType": "Over"},
  ];

  void onTapNewRoom() => Navigator.pushNamed(context, '/newclassroom');
  void onTapRecorded() => Navigator.pushNamed(context, '/downloading');
  void onTapJoinRoom() => Navigator.pushNamed(context, '/classroom');

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          "PHADAAI",
          style: GoogleFonts.roboto(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.w900,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Stack(
        children: [
          // ✅ Fixed Lottie animation background
          SizedBox(
            width: screenWidth,
            height: 300,
            child: Lottie.asset(
              'assets/STUDENT.json',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Scrollable content that flows over the animation
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 300), // Push content below the animation

                // White container for scrolling content
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      HomeCard(
                        onTapRecorded: onTapRecorded,
                        onTapNewRoom: onTapNewRoom,
                        onTapJoinRoom: onTapJoinRoom,
                      ),
                      const SizedBox(height: 16),

                      // Section title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Your Classes",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // List of classes
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: classList.length,
                        itemBuilder: (context, index) {
                          final classData = classList[index];
                          return ClassTile(
                            className: classData['className'],
                            creatorName: classData['creatorName'],
                            classType: classData['classType'],
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
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

/// ✅ ClassTile Widget
class ClassTile extends StatelessWidget {
  final String className;
  final String creatorName;
  final String classType; // Live | Planned | Over

  const ClassTile({
    super.key,
    required this.className,
    required this.creatorName,
    required this.classType,
  });

  Color _getStatusColor(BuildContext context) {
    switch (classType) {
      case "Live":
        return Colors.green;
      case "Planned":
        return Colors.orange;
      case "Over":
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.inversePrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.secondary,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          className,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        subtitle: Text(
          "By $creatorName",
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(context).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            classType,
            style: TextStyle(
              color: _getStatusColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
