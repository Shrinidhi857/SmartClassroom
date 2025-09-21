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
                    Icon(
                      Icons.storage,
                      size: 48.0,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Recorded',
                      style: TextStyle(
                        fontSize: 18,
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
                    Icon(
                      Icons.new_label,
                      size: 48.0,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'JoinRoom',
                      style: TextStyle(
                        fontSize: 18,
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
                    Icon(
                      Icons.new_label,
                      size: 48.0,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'New Room',
                      style: TextStyle(
                        fontSize: 18,
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
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.inversePrimary, // ✅ works
              width: 2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
