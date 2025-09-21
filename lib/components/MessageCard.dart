import 'package:flutter/material.dart';
import "MessagesModel.dart";

/// A widget that displays a scrollable list of chat messages.
class MessageList extends StatelessWidget {
  final List<Message> messages;

  const MessageList({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias, // Ensures child respects the border radius
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          // ListView.builder is efficient for long lists of items.
          child: ListView.builder(
            // Reversing the list shows new messages at the bottom.
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _MessageBubble(message: message);
            },
          ),
        ),
      ),
    );
  }
}

/// A private widget to style individual message bubbles.
class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSent = message.isSent;

    return Align(
      // Align bubbles to the right for sent, and left for received.
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          // Set a max width for the bubbles to prevent them from taking the full screen width.
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSent
              ? theme.colorScheme.inversePrimary
              : theme.colorScheme.tertiary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
            isSent ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight:
            isSent ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isSent
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.inversePrimary,
          ),
        ),
      ),
    );
  }
}
