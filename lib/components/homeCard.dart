import 'package:flutter/material.dart';
import '../pages/NewClassroomPage.dart';
import 'dialogbox.dart';
import 'joinDialogbox.dart';

class HomeCard extends StatelessWidget {
  final VoidCallback? onTapRecorded;
  final VoidCallback? onTapNewRoom;
  final VoidCallback? onTapJoinRoom;

  const HomeCard({
    Key? key,
    this.onTapRecorded,
    this.onTapJoinRoom,
    this.onTapNewRoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Download button
            Expanded(
              child: _buildButton(
                context: context,
                onTap: onTapRecorded,
                child: _buttonContent(
                  context,
                  icon: 'assets/images/workplace.png',
                  label: 'Download',
                ),
              ),
            ),
            const SizedBox(width: 16.0),

            // Join Room button
            Expanded(
              child: _buildButton(
                context: context,
                onTap: () async {
                  final result = await showJoinClassDialog(context);
                  if (result != null) {
                    debugPrint('✅ Classroom Name: ${result['classroomName']}');
                    debugPrint('👤 Creator Name: ${result['creatorName']}');

                    // 👇 Navigate to NewClassroomPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewClassroomPage(
                          roomId: result['classroomid']!,   // use classroomName as roomId
                          username: result['userName']!,  // pass creator name
                          serverUrl: "wss://websocketboard.onrender.com", // keep same server
                        ),
                      ),
                    );
                  }
                },
                child: _buttonContent(
                  context,
                  icon: 'assets/images/videoconference.png',
                  label: 'Join Room',
                ),
              ),
            ),
            const SizedBox(width: 16.0),

            // New Room button (opens dialog)
            // New Room button (opens dialog)
            Expanded(
              child: _buildButton(
                context: context,
                onTap: () async {
                  final result = await showCreateClassDialog(context);
                  if (result != null) {
                    debugPrint('✅ Classroom Name: ${result['classroomName']}');
                    debugPrint('👤 Creator Name: ${result['creatorName']}');

                    // 👇 Navigate to NewClassroomPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewClassroomPage(
                          roomId: result['classroomName']!,   // use classroomName as roomId
                          username: result['creatorName']!,  // pass creator name
                          serverUrl: "wss://websocketboard.onrender.com", // keep same server
                        ),
                      ),
                    );
                  }
                },
                child: _buttonContent(
                  context,
                  icon: 'assets/images/classroom.png',
                  label: 'New Room',
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// Reusable square button
  Widget _buildButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: AspectRatio(
        aspectRatio: 1 / 1, // square
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Content inside each button (icon + label)
  Widget _buttonContent(BuildContext context,
      {required String icon, required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Image.asset(
            icon,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ],
    );
  }
}
