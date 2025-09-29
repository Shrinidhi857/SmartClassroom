import 'package:flutter/material.dart';

class ClassTile extends StatefulWidget {
  final String classroomName;
  final String creatorName;
  final String classType;
  final String status; // "live", "planned", "over"
  final List<String> sessionList;

  const ClassTile({
    super.key,
    required this.classroomName,
    required this.creatorName,
    required this.classType,
    required this.status,
    required this.sessionList,
  });

  @override
  State<ClassTile> createState() => _ClassTileState();
}

class _ClassTileState extends State<ClassTile> {
  bool _isExpanded = false;

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'live':
        return Colors.green;
      case 'planned':
        return Colors.orange;
      case 'over':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (widget.status.toLowerCase()) {
      case 'live':
        return 'Live';
      case 'planned':
        return 'Planned';
      case 'over':
        return 'Over';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status.toLowerCase()) {
      case 'live':
        return Icons.wifi_tethering;
      case 'planned':
        return Icons.schedule;
      case 'over':
        return Icons.stop_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header row (Classroom + Status)
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Classroom + Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.classroomName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "👤 ${widget.creatorName}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "📚 ${widget.classType}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  // Right side: Status chip + expand icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStatusColor(), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(),
                              color: _getStatusColor(),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusLabel(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Expanded list of sessions
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              if (widget.sessionList.isEmpty)
                Text(
                  "No sessions available.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.sessionList.map((session) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "📝 $session",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ]
          ],
        ),
      ),
    );
  }
}
