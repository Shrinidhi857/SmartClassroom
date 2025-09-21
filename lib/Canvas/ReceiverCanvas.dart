import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Custom drawing data models
class DrawingPoint {
  final Offset point;
  final Paint paint;
  final int timestamp;

  DrawingPoint({
    required this.point,
    required this.paint,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': point.dx,
      'y': point.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'timestamp': timestamp,
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    final paint = Paint()
      ..color = Color(json['color'] as int)
      ..strokeWidth = (json['strokeWidth'] as num).toDouble()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    return DrawingPoint(
      point: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      paint: paint,
      timestamp: json['timestamp'] as int,
    );
  }
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final String id;
  final String senderId;
  final int startTime;

  DrawingStroke({
    required this.points,
    required this.id,
    required this.senderId,
    required this.startTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'startTime': startTime,
      'points': points.map((p) => p.toJson()).toList(),
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      startTime: json['startTime'] as int,
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Custom Drawing Painter for Receiver (Read-only)
class ReceiverDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final Map<String, DrawingStroke> remoteStrokes;

  ReceiverDrawingPainter({
    required this.strokes,
    required this.remoteStrokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw active remote strokes
    for (final remoteStroke in remoteStrokes.values) {
      _drawStroke(canvas, remoteStroke);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();
    final paint = stroke.points.first.paint;

    // Start path
    path.moveTo(stroke.points.first.point.dx, stroke.points.first.point.dy);

    // Add points to path
    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i].point;
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Receiver Canvas Widget (Read-only)
class ReceiverCanvas extends StatefulWidget {
  final String? roomId;
  final String? username;
  final String serverUrl;

  const ReceiverCanvas({
    Key? key,
    this.roomId,
    this.username,
    this.serverUrl = 'http://10.243.255.250:3000',
  }) : super(key: key);

  @override
  _ReceiverCanvasState createState() => _ReceiverCanvasState();
}

class _ReceiverCanvasState extends State<ReceiverCanvas>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late IO.Socket socket;

  // Drawing state (read-only for receiver)
  List<DrawingStroke> _completedStrokes = [];
  Map<String, DrawingStroke> _remoteStrokes = {};

  // Room and connection state
  String? _currentRoomId;
  String? _clientId;
  bool _isConnected = false;
  bool _isInRoom = false;
  int _clientsInRoom = 0;
  String _connectionStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.roomId ?? 'default-room';
    _initializeSocket();
    _setupSocketListeners();
  }

  void _initializeSocket() {
    socket = IO.io(widget.serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'forceNew': true,      // 👈 ensures unique socket per widget
      'autoConnect': false,  // 👈 connect manually
      'reconnection': true,
    });
    socket.connect();
  }


  void _setupSocketListeners() {
    socket.on('connect', (_) {
      print('Socket connected');
      setState(() {
        _isConnected = true;
        _connectionStatus = 'Connected';
      });
      _identifyClient();
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
      setState(() {
        _isConnected = false;
        _isInRoom = false;
        _connectionStatus = 'Disconnected';
        _clientsInRoom = 0;
      });
    });

    socket.on('connect_error', (error) {
      print('Connection error: $error');
      setState(() {
        _connectionStatus = 'Connection Error';
      });
    });

    socket.on('welcome', (data) {
      print('Welcome received: $data');
      setState(() {
        _clientId = data['clientId'];
      });
    });

    socket.on('identified', (data) {
      print('Identified: $data');
      if (data['success']) {
        _joinRoom(_currentRoomId!);
      }
    });
    socket.on('stroke', (data) {
      print('Received stroke JSON: $data');
      _handleRemoteStroke(data);
    });

    socket.on('stroke-complete', (data) {
      print('Received stroke-complete JSON: $data');
      _handleRemoteStrokeComplete(data);
    });


    socket.on('joined-room', (data) {
      print('Joined room: $data');
      setState(() {
        _isInRoom = true;
        _clientsInRoom = data['clientsInRoom'] ?? 0;
        _connectionStatus = 'In Room: ${data['roomId']} (Viewer)';
      });
    });

    socket.on('user-joined', (data) {
      print('User joined: $data');
      setState(() {
        _clientsInRoom = data['clientsInRoom'] ?? _clientsInRoom;
      });
    });

    socket.on('user-left', (data) {
      print('User left: $data');
      setState(() {
        _clientsInRoom = data['clientsInRoom'] ?? _clientsInRoom;
      });
    });

    // Drawing synchronization (receive only)
    socket.on('stroke', (data) {
      print('Received stroke: $data');
      _handleRemoteStroke(data);
    });

    socket.on('stroke-complete', (data) {
      print('Stroke complete: $data');
      _handleRemoteStrokeComplete(data);
    });

    socket.on('clear-board', (data) {
      print('Clear board received');
      setState(() {
        _completedStrokes.clear();
        _remoteStrokes.clear();
      });
    });

    socket.on('undo', (data) {
      print('Undo received');
      _handleUndo();
    });

    // Request current board state when joining
    socket.on('board-state', (data) {
      print('Board state received: $data');
      _handleBoardState(data);
    });
  }

  void _identifyClient() {
    socket.emit('identify', {
      'type': 'receiver',
      'username': widget.username ?? 'Viewer',
    });
  }

  void _joinRoom(String roomId) {
    socket.emit('join-room', {
      'roomId': roomId,
    });

    // Request current board state
    socket.emit('request-board-state');
  }

  void _handleBoardState(Map<String, dynamic> data) {
    try {
      final strokes = data['strokes'] as List?;
      if (strokes != null) {
        setState(() {
          _completedStrokes = strokes
              .map((strokeData) => DrawingStroke.fromJson(strokeData as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('Error handling board state: $e');
    }
  }

  void _handleRemoteStroke(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      // The point is probably nested inside "point"
      final pointJson = data['point'] ?? data;
      final point = DrawingPoint.fromJson(pointJson as Map<String, dynamic>);
      final strokeId = data['strokeId'] as String;
      final senderId = data['senderId'] as String;

      setState(() {
        if (_remoteStrokes.containsKey(strokeId)) {
          _remoteStrokes[strokeId]!.points.add(point);
        } else {
          _remoteStrokes[strokeId] = DrawingStroke(
            id: strokeId,
            senderId: senderId,
            startTime: point.timestamp,
            points: [point],
          );
        }
      });
    } catch (e) {
      print('Error handling remote stroke: $e');
    }
  }


  void _handleRemoteStrokeComplete(Map<String, dynamic> data) {
    try {
      if (data.containsKey('stroke')) {
        // Full stroke object
        final stroke = DrawingStroke.fromJson(data['stroke']);
        setState(() {
          _completedStrokes.add(stroke);
          _remoteStrokes.remove(stroke.id);
        });
      } else {
        // Only strokeId
        final strokeId = data['strokeId'] as String;
        if (_remoteStrokes.containsKey(strokeId)) {
          setState(() {
            _completedStrokes.add(_remoteStrokes[strokeId]!);
            _remoteStrokes.remove(strokeId);
          });
        }
      }
    } catch (e) {
      print('Error handling stroke complete: $e');
    }
  }


  void _handleUndo() {
    setState(() {
      if (_completedStrokes.isNotEmpty) {
        _completedStrokes.removeLast();
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    double cardHeight;
    if (keyboardHeight > 0) {
      cardHeight = (screenHeight - keyboardHeight) * 0.4;
    } else {
      cardHeight = screenWidth * 0.8;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Connection status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isConnected
                  ? (_isInRoom ? Colors.blue.shade100 : Colors.orange.shade100)
                  : Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected
                      ? (_isInRoom ? Icons.visibility : Icons.wifi_tethering)
                      : Icons.wifi_off,
                  size: 16,
                  color: _isConnected
                      ? (_isInRoom ? Colors.blue : Colors.orange)
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionStatus,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isInRoom) ...[
                  const Icon(Icons.people, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '$_clientsInRoom',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          // Drawing area (Read-only)
          Flexible(
            child: Container(
              width: screenWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: Stack(
                  children: [
                    // Drawing canvas (no gesture detection - read-only)
                    CustomPaint(
                      painter: ReceiverDrawingPainter(
                        strokes: _completedStrokes,
                        remoteStrokes: _remoteStrokes,
                      ),
                      size: Size(screenWidth, cardHeight),

                    ),

                    // Viewer indicator overlay
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),

                    // Connection status overlay (when not connected)
                    if (!_isConnected || !_isInRoom)
                      Container(
                        width: screenWidth,
                        height: cardHeight,
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isConnected ? Icons.hourglass_empty : Icons.wifi_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isConnected ? 'Joining Room...' : 'Connecting...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _connectionStatus,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}