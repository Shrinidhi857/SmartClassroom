import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ReceiverCanvasDrawingCard extends StatefulWidget {
  const ReceiverCanvasDrawingCard({Key? key}) : super(key: key);

  @override
  _ReceiverCanvasDrawingCardState createState() => _ReceiverCanvasDrawingCardState();
}

class _ReceiverCanvasDrawingCardState extends State<ReceiverCanvasDrawingCard> {
  final DrawingController _controller = DrawingController();
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();

    // Initialize socket
    socket = IO.io('http://10.243.255.250:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.on('connect', (_){
      print('Receiver connected to server');
      _showSnackBar("✅ Connected to server");
    });
    socket.on('disconnect', (_) {
      print('Receiver disconnected');
    _showSnackBar("❌ Disconnected from server");
    });

    // Listen for incoming strokes from the creator
    socket.on('drawing', (data) {
      if (data != null) {
        // Recreate paint style
        final paint = Paint()
          ..color = Color(int.parse(data['color'], radix: 16))
          ..strokeWidth = (data['strokeWidth'] ?? 2.0).toDouble()
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        // Just to show: here you'd ideally also pass stroke path/points.
        // For now, only metadata is available.
        // If you transmit points too, you can rebuild strokes fully.

        print("Received stroke metadata: $data");

        // Example: add dummy stroke (needs actual points for real drawing)
        // _controller.addStroke(DrawingStroke(points, paint));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    double cardHeight;
    if (keyboardHeight > 0) {
      cardHeight = (screenHeight - keyboardHeight) * 0.4;
    } else {
      cardHeight = screenWidth * 0.8;
    }

    return  Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      margin: const EdgeInsets.all(10),
      child:Column(
        children: [
          Expanded(
    child: Container(
        width: screenWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child:  ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          // AbsorbPointer blocks all pointer events to the DrawingBoard (no drawing, no taps).
          child: AbsorbPointer(
            absorbing: true, // set to false if you want the receiver to be interactive later
            child: DrawingBoard(
              controller: _controller,
              background: Container(width: screenWidth, height: cardHeight, color: Colors.white),
              showDefaultActions: false,
              showDefaultTools: false,
              // you can still configure pan/scale options here, but note AbsorbPointer will block user gestures
              boardPanEnabled: true,
              boardScaleEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
            ),
          ),
        ),
      ),
    )
    ]));
  }
}
