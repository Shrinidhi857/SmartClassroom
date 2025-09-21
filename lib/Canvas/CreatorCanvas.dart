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

// Custom Drawing Painter
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Map<String, DrawingStroke> remoteStrokes;

  DrawingPainter({
    required this.strokes,
    this.currentStroke,
    required this.remoteStrokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw remote strokes
    for (final remoteStroke in remoteStrokes.values) {
      _drawStroke(canvas, remoteStroke);
    }

    // Draw current stroke being drawn
    if (currentStroke != null && currentStroke!.points.isNotEmpty) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  // In your DrawingPainter class
  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    // Do nothing if there are no points
    if (stroke.points.isEmpty) return;

    // If there's only one point (a tap), draw a small circle
    if (stroke.points.length == 1) {
      final point = stroke.points.first;
      canvas.drawCircle(point.point, point.paint.strokeWidth / 2, point.paint);
      return;
    }

    // For a continuous line, draw segments between each pair of points
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];

      // Draw a line from point 1 to point 2
      canvas.drawLine(p1.point, p2.point, p1.paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Creator Canvas Widget
class CreatorCanvas extends StatefulWidget {
  final String? roomId;
  final String? username;
  final String serverUrl;

  const CreatorCanvas({
    Key? key,
    this.roomId,
    this.username,
    this.serverUrl = 'http://10.243.255.250:3000',
  }) : super(key: key);

  @override
  _CreatorCanvasState createState() => _CreatorCanvasState();
}

class _CreatorCanvasState extends State<CreatorCanvas> {
  late IO.Socket socket;

  // Drawing state
  List<DrawingStroke> _completedStrokes = [];
  DrawingStroke? _currentStroke;
  Map<String, DrawingStroke> _remoteStrokes = {};
  Color _selectedColor = Colors.black;
  double _strokeWidth = 2.0;

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
      'forceNew': true,
      'autoConnect': false,
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

    socket.on('joined-room', (data) {
      print('Joined room: $data');
      setState(() {
        _isInRoom = true;
        _clientsInRoom = data['clientsInRoom'] ?? 0;
        _connectionStatus = 'In Room: ${data['roomId']}';
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

    // Drawing synchronization
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
        _currentStroke = null;
      });
    });

    socket.on('undo', (data) {
      print('Undo received');
      _handleUndo();
    });
  }

  void _identifyClient() {
    socket.emit('identify', {
      'type': 'creator',
      'username': widget.username ?? 'Creator',
    });
  }

  void _joinRoom(String roomId) {
    socket.emit('join-room', {
      'roomId': roomId,
    });
  }

  void _handleRemoteStroke(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      final point = DrawingPoint.fromJson(data);
      final strokeId = data['strokeId'] as String;
      final senderId = data['senderId'] as String;

      // Skip if it's our own stroke
      if (senderId == _clientId) return;

      setState(() {
        if (_remoteStrokes.containsKey(strokeId)) {
          // Add point to existing remote stroke
          _remoteStrokes[strokeId]!.points.add(point);
        } else {
          // Create new remote stroke
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
    final strokeId = data['strokeId'] as String;
    print('Remote stroke completed: $strokeId');

    // Move completed remote stroke to permanent storage
    if (_remoteStrokes.containsKey(strokeId)) {
      setState(() {
        _completedStrokes.add(_remoteStrokes[strokeId]!);
        _remoteStrokes.remove(strokeId);
      });
    }
  }

  void _handleUndo() {
    setState(() {
      if (_completedStrokes.isNotEmpty) {
        _completedStrokes.removeLast();
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isInRoom) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final paint = Paint()
      ..color = _selectedColor
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final point = DrawingPoint(
      point: localPosition,
      paint: paint,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final strokeId = '${_clientId}_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _currentStroke = DrawingStroke(
        id: strokeId,
        senderId: _clientId ?? 'unknown',
        startTime: point.timestamp,
        points: [point],
      );
    });

    // Send point to server
    socket.emit('stroke', {
      ...point.toJson(),
      'strokeId': strokeId,
    });
  }

  // In _CreatorCanvasState class

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isInRoom || _currentStroke == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // **FIX:** Reuse the paint object instead of creating a new one.
    final paint = _currentStroke!.points.first.paint;

    final point = DrawingPoint(
      point: localPosition,
      paint: paint, // This is much more efficient
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _currentStroke!.points.add(point);
    });

    socket.emit('stroke', {
      ...point.toJson(),
      'strokeId': _currentStroke!.id,
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isInRoom || _currentStroke == null) return;

    setState(() {
      _completedStrokes.add(_currentStroke!);
      final strokeId = _currentStroke!.id;
      _currentStroke = null;

      // Notify server that stroke is complete
      socket.emit('stroke-complete', {
        'strokeId': strokeId,
      });
    });
  }

  void _clearBoard() {
    setState(() {
      _completedStrokes.clear();
      _remoteStrokes.clear();
      _currentStroke = null;
    });

    if (_isInRoom) {
      socket.emit('clear-board');
    }
  }

  void _undoAction() {
    setState(() {
      if (_completedStrokes.isNotEmpty) {
        _completedStrokes.removeLast();
      }
    });

    if (_isInRoom) {
      socket.emit('undo');
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
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
                  ? (_isInRoom ? Colors.green.shade100 : Colors.orange.shade100)
                  : Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected
                      ? (_isInRoom ? Icons.wifi : Icons.wifi_tethering)
                      : Icons.wifi_off,
                  size: 16,
                  color: _isConnected
                      ? (_isInRoom ? Colors.green : Colors.orange)
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
                  const Icon(Icons.people, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '$_clientsInRoom',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          // Drawing area
          Flexible(
            child: Container(
              width: screenWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: Stack(
                  children: [
                    // Drawing canvas
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: DrawingPainter(
                            strokes: _completedStrokes,
                            currentStroke: _currentStroke,
                            remoteStrokes: _remoteStrokes,
                          ),
                          size: Size(screenWidth, cardHeight),

                        )

                      ),
                    ),

                    // Controls overlay
                    // Color palette
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildColorPalette(),
                    ),
                    // Action buttons
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildActionButtons(),
                    ),
                    // Stroke width slider
                    Positioned(
                      bottom: 5,
                      left: 5,
                      right: 5,
                      child: _buildStrokeWidthSlider(),
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

  Widget _buildColorPalette() {
    final colors = [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: colors.map((color) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == color ? Colors.black : Colors.grey.shade400,
                  width: _selectedColor == color ? 3 : 1,
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionButton(Icons.undo, _undoAction),
          const SizedBox(height: 8),
          _buildActionButton(Icons.clear, _clearBoard),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('Width: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Slider(
              value: _strokeWidth,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              onChanged: (value) => setState(() => _strokeWidth = value),
              activeColor: _selectedColor,
            ),
          ),
          Text('${_strokeWidth.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}