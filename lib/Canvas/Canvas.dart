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

  DrawingPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke being drawn
    if (currentStroke != null && currentStroke!.points.isNotEmpty) {
      _drawStroke(canvas, currentStroke!);
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

// Main Drawing Widget
class SyncDrawingCard extends StatefulWidget {
  final bool isDrawingEnabled;
  final String? roomId;
  final String? username;
  final String clientType;

  const SyncDrawingCard({
    Key? key,
    this.isDrawingEnabled = true,
    this.roomId,
    this.username,
    this.clientType = 'creator',
  }) : super(key: key);

  @override
  _SyncDrawingCardState createState() => _SyncDrawingCardState();
}

class _SyncDrawingCardState extends State<SyncDrawingCard> {
  late IO.Socket socket;

  // Drawing state
  List<DrawingStroke> _completedStrokes = [];
  DrawingStroke? _currentStroke;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 2.0;
  late bool isDrawingEnabled;

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
    isDrawingEnabled = widget.isDrawingEnabled;
    _currentRoomId = widget.roomId ?? 'default-room';

    _initializeSocket();
    _setupSocketListeners();
  }

  void _initializeSocket() {
    socket = IO.io('http://10.243.255.250:3000', <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
    });
  }

  void _setupSocketListeners() {
    socket.on('connect', (_) {
      setState(() {
        _isConnected = true;
        _connectionStatus = 'Connected';
      });
      _identifyClient();
    });

    socket.on('disconnect', (_) {
      setState(() {
        _isConnected = false;
        _isInRoom = false;
        _connectionStatus = 'Disconnected';
        _clientsInRoom = 0;
      });
    });

    socket.on('welcome', (data) {
      setState(() {
        _clientId = data['clientId'];
      });
    });

    socket.on('identified', (data) {
      if (data['success']) {
        _joinRoom(_currentRoomId!);
      }
    });

    socket.on('joined-room', (data) {
      setState(() {
        _isInRoom = true;
        _clientsInRoom = data['clientsInRoom'] ?? 0;
        _connectionStatus = 'In Room: ${data['roomId']}';
      });
    });

    socket.on('user-joined', (data) {
      setState(() {
        _clientsInRoom = data['clientsInRoom'] ?? _clientsInRoom;
      });
    });

    socket.on('user-left', (data) {
      setState(() {
        _clientsInRoom = data['clientsInRoom'] ?? _clientsInRoom;
      });
    });

    // Drawing synchronization
    socket.on('stroke', (data) {
      _handleRemoteStroke(data);
    });

    socket.on('stroke-complete', (data) {
      _handleRemoteStrokeComplete(data);
    });

    socket.on('clear-board', (data) {
      setState(() {
        _completedStrokes.clear();
        _currentStroke = null;
      });
    });

    socket.on('undo', (data) {
      _handleUndo();
    });
  }

  void _identifyClient() {
    socket.emit('identify', {
      'type': widget.clientType,
      'username': widget.username ?? 'Anonymous',
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

      setState(() {
        // Find existing remote stroke or create new one
        DrawingStroke? existingStroke;
        for (int i = 0; i < _completedStrokes.length; i++) {
          if (_completedStrokes[i].id == strokeId) {
            existingStroke = _completedStrokes[i];
            break;
          }
        }

        if (existingStroke != null) {
          // Add point to existing stroke
          existingStroke.points.add(point);
        } else {
          // Create new stroke
          final newStroke = DrawingStroke(
            id: strokeId,
            senderId: senderId,
            startTime: point.timestamp,
            points: [point],
          );
          _completedStrokes.add(newStroke);
        }
      });
    } catch (e) {
      print('Error handling remote stroke: $e');
    }
  }

  void _handleRemoteStrokeComplete(Map<String, dynamic> data) {
    // Handle when remote user completes a stroke
    print('Remote stroke completed: ${data['strokeId']}');
  }

  void _handleUndo() {
    setState(() {
      if (_completedStrokes.isNotEmpty) {
        _completedStrokes.removeLast();
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!isDrawingEnabled || !_isInRoom) return;

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

  void _onPanUpdate(DragUpdateDetails details) {
    if (!isDrawingEnabled || !_isInRoom || _currentStroke == null) return;

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

    setState(() {
      _currentStroke!.points.add(point);
    });

    // Send point to server
    socket.emit('stroke', {
      ...point.toJson(),
      'strokeId': _currentStroke!.id,
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!isDrawingEnabled || !_isInRoom || _currentStroke == null) return;

    setState(() {
      _completedStrokes.add(_currentStroke!);
      _currentStroke = null;
    });

    // Notify server that stroke is complete
    socket.emit('stroke-complete', {
      'strokeId': _completedStrokes.last.id,
    });
  }

  void _clearBoard() {
    setState(() {
      _completedStrokes.clear();
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
                  Icon(Icons.people, size: 16, color: Colors.green),
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
                    GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: DrawingPainter(
                          strokes: _completedStrokes,
                          currentStroke: _currentStroke,
                        ),
                        size: Size(screenWidth, cardHeight),
                        child: Container(
                          width: screenWidth,
                          height: cardHeight,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Controls overlay
                    if (isDrawingEnabled) ...[
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