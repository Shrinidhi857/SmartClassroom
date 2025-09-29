import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  final void Function()? onTapRecorded;
  final void Function()? onTapNewRoom;
  final void Function()? onTapJoinRoom;

  const HomeCard({
    Key? key,
    this.onTapRecorded,
    this.onTapJoinRoom,
    this.onTapNewRoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Using a Card for the main container to get a nice shadow and rounded corners.
    return Card(
      margin: EdgeInsets.only(left: 5,right: 5),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding:  EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildButton(
                context: context,
                onTap: onTapRecorded,
                // A Column to stack the icon and text vertically
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/images/workplace.png',
                  height:60,
                  fit: BoxFit.cover,
                ),
              ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16.0), // Spacing between the buttons
            // Right button for "New Room"
            Expanded(
              child: _buildButton(
                context: context,
                onTap: onTapJoinRoom,
                // A Column to stack the icon and text vertically
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/images/videoconference.png',
                        height:60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'JoinRoom',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ],
                ),

              ),
            ),
            const SizedBox(width: 16.0), // Spacing between the buttons
            // Right button for "New Room"
            Expanded(
              child: _buildButton(
                context: context,
                onTap: onTapNewRoom,
                // A Column to stack the icon and text vertically
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/images/classroom.png',
                        height:60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'New Room',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ],
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: Container(
          decoration: BoxDecoration(
            color:Theme.of(context).colorScheme.primary ,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: child,
        ),
      ),
    );
  }
}
