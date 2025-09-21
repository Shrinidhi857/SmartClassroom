class Message {
  final String text;
  final bool isSent; // true for sent messages, false for received.

  Message({required this.text, required this.isSent});
}
