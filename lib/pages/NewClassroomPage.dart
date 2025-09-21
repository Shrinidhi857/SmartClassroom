import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sihapp/Canvas/Canvas.dart';
import 'package:sihapp/components/AskQuestion.dart';
import 'package:sihapp/components/MessageCard.dart';

import '../Canvas/CreatorCanvas.dart';
import '../Canvas/ReceiverCanvas.dart';
import '../components/MessagesModel.dart';

class ClassroomPage extends StatefulWidget {
  const ClassroomPage({super.key});

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> with SingleTickerProviderStateMixin {

  void onTapRecored() async {}

  void onTapNewRoom() async {}

  void onSendMessage() async {}
  bool _showMessagesOverlay = false;

  final List<Message> messages = [
    Message(text: "Hey, how are you?", isSent: false),
    Message(text: "I'm good, thanks! How about you?", isSent: true),
    Message(text: "Doing great. Working on a Flutter app 😃", isSent: false),
    Message(text: "That's awesome 🚀", isSent: true),
  ];

  void _handleSendMessage(String text) {
    setState(() {
      messages.insert(0, Message(text: text, isSent: true));
      // insert at 0 because your MessageList is reversed
    });
  }


  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery
        .of(context)
        .orientation;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .primary,
      appBar: orientation == Orientation.portrait ? AppBar(
        title: Text(
          "SIH",
          style: GoogleFonts.roboto(
            color: Theme
                .of(context)
                .colorScheme
                .inversePrimary,
            fontWeight: FontWeight.w900,
            fontSize: 25,
          ),
        ),
      ) : null,

      body: orientation == Orientation.portrait
          ? _buildPortraitLayout()
          : _buildLandscapeLayout(),
    );
  }

  /// Portrait Layout (same as now)
  Widget _buildPortraitLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Drawing board stays fixed
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child:ReceiverCanvas(
              roomId: 'your-room-id', // Same room ID as creator
              username: 'Viewer Name',
              serverUrl: 'wss://websocketboard.onrender.com',
            )

          ),
          /*SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: CreatorCanvas(
                roomId: 'your-room-id',
                username: 'Creator Name',
                serverUrl: 'wss://websocketboard.onrender.com',
              )

          ),*/


          Expanded(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Container(

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.mic, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showMessagesOverlay = !_showMessagesOverlay;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 40,),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green,
                      child: IconButton(
                        icon: const Icon(Icons.help, color: Colors.white,size: 25,),
                        onPressed: () {
                          // handle questions overlay here
                        },
                      ),
                    ),
                  ],
                ),
                margin: EdgeInsets.only(left: 12,right: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color:Theme.of(context).colorScheme.secondary

                ),
              ),
            ),
            MessageList(messages: messages),


          ],
          )),

          // Input box sticks to bottom, moves up with keyboard
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: QuestionInput(onSendMessage: _handleSendMessage),
          ),]
          )
    );
  }



  /// Landscape Layout
  Widget _buildLandscapeLayout() {
    return SingleChildScrollView( // <--- WRAP the Row with this widget
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align children to the top
        children: [
          // Left: Drawing board with overlay
          Expanded(
            flex: 4,
            child: AspectRatio( // Use AspectRatio to maintain a consistent shape
              aspectRatio: 16 / 9, // Or any ratio that fits your design
              child: Stack(
                children: [
                  // Canvas fills all available space
                  Positioned.fill(
                    child: ReceiverCanvas(
                      roomId: 'your-room-id', // Same room ID as creator
                      username: 'Viewer Name',
                      serverUrl: 'wss://websocketboard.onrender.com',
                    )

                  ),

                  // Overlay for messages (takes part of screen height)
                  if (_showMessagesOverlay)
                    Align(
                      alignment: Alignment.topRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.5, // 90% width of canvas
                        heightFactor: .7, // 40% height of canvas
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: MessageList(messages: messages),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Right: Circular buttons only
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(

              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.message, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showMessagesOverlay = !_showMessagesOverlay;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showMessagesOverlay = !_showMessagesOverlay;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green,
                  child: IconButton(
                    icon: const Icon(Icons.help, color: Colors.white),
                    onPressed: () {
                      // handle questions overlay here
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}