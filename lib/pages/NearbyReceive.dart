import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/NearbyStudent.dart'; // <-- make sure this path is correct
import 'package:nearby_connections/nearby_connections.dart' as nc;

class NearbyreceivePage extends StatefulWidget {
  const NearbyreceivePage({super.key});

  @override
  State<NearbyreceivePage> createState() => _NearbyreceivePageState();
}

class _NearbyreceivePageState extends State<NearbyreceivePage> {
  final TextEditingController _searchController = TextEditingController();

  // Dynamic data - starts empty, populated through discovery
  final List<Map<String, dynamic>> students = [];

  // filtered view shown in the list
  List<Map<String, dynamic>> filteredStudents = [];

  // Discovery state
  bool _isDiscovering = false;
  final Set<String> _connectedEndpoints = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _filterStudents(_searchController.text));
    filteredStudents = List<Map<String, dynamic>>.from(students);
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    if (_isDiscovering) return;

    setState(() {
      _isDiscovering = true;
    });

    try {
      await nc.Nearby().startDiscovery(
        "com.example.my_nearby_service",
        nc.Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          debugPrint("Found endpoint: $name ($id)");
          _requestConnection(id, name);
        },
        onEndpointLost: (id) {
          debugPrint("Lost endpoint: $id");
          _connectedEndpoints.remove(id);
        },
      );
    } catch (e) {
      debugPrint("Error starting discovery: $e");
      setState(() {
        _isDiscovering = false;
      });
    }
  }

  Future<void> _stopDiscovery() async {
    try {
      await nc.Nearby().stopDiscovery();
      setState(() {
        _isDiscovering = false;
      });
    } catch (e) {
      debugPrint("Error stopping discovery: $e");
    }
  }

  void _requestConnection(String endpointId, String endpointName) {
    if (_connectedEndpoints.contains(endpointId)) return;

    nc.Nearby().requestConnection(
      "Receiver_${DateTime.now().millisecondsSinceEpoch}",
      endpointId,
      onConnectionInitiated: (endpointId, info) {
        debugPrint("Connection initiated with: ${info.endpointName}");
        nc.Nearby().acceptConnection(
          endpointId,
          onPayLoadRecieved: (endid, payload) {
            _handlePayload(endid, payload);
          },
          onPayloadTransferUpdate: (endid, update) {
            debugPrint("Transfer update: ${update.status}");
          },
        );
      },
      onConnectionResult: (id, status) {
        debugPrint("Connection result for $id: $status");
        if (status == nc.Status.CONNECTED) {
          _connectedEndpoints.add(id);
        }
      },
      onDisconnected: (id) {
        debugPrint("Disconnected: $id");
        _connectedEndpoints.remove(id);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stopDiscovery();
    nc.Nearby().stopAllEndpoints();
    super.dispose();
  }

  void _filterStudents(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredStudents = List<Map<String, dynamic>>.from(students);
      } else {
        filteredStudents = students.where((student) {
          final name = (student['name']?.toString() ?? '').toLowerCase();

          // handle docs that might be List<dynamic> or even null
          final docs = (student['docs'] is Iterable)
              ? (student['docs'] as Iterable)
              .map((d) => d?.toString().toLowerCase() ?? '')
              .toList()
              : <String>[];

          final nameMatches = name.contains(query);
          final docMatches = docs.any((d) => d.contains(query));
          return nameMatches || docMatches;
        }).toList();
      }
    });

    debugPrint('Search "$query" -> ${filteredStudents.length} result(s)');
  }

  void _handlePayload(String endpointId, nc.Payload payload) {
    if (payload.type == nc.PayloadType.BYTES) {
      final text = String.fromCharCodes(payload.bytes!);
      debugPrint("Received payload from $endpointId: $text");

      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          // Check if student already exists (avoid duplicates)
          final existingIndex = students.indexWhere(
                  (student) => student["name"] == decoded["name"]
          );

          setState(() {
            if (existingIndex != -1) {
              // Update existing student's docs
              final existingDocs = List<String>.from(students[existingIndex]["docs"] ?? []);
              final newDocs = List<String>.from(decoded["docs"] ?? []);

              // Merge docs without duplicates
              final mergedDocs = {...existingDocs, ...newDocs}.toList();
              students[existingIndex]["docs"] = mergedDocs;
            } else {
              // Add new student
              students.add({
                "name": decoded["name"],
                "docs": List<String>.from(decoded["docs"] ?? []),
                "endpointId": endpointId, // Track which endpoint this came from
              });
            }

            // Refresh filtered list
            _filterStudents(_searchController.text);
          });

          debugPrint("Added/Updated student: ${decoded["name"]}");
        }
      } catch (e) {
        debugPrint("Error parsing JSON payload: $e");
      }
    }
  }

  void _refreshDiscovery() {
    _stopDiscovery().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _startDiscovery();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          "📥 Manual Receiver",
          style: GoogleFonts.roboto(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.w900,
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDiscovering ? Icons.stop : Icons.refresh,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: _isDiscovering ? _stopDiscovery : _refreshDiscovery,
            tooltip: _isDiscovering ? 'Stop Discovery' : 'Refresh Discovery',
          ),
        ],
      ),
      body: Column(
        children: [
          // Discovery status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isDiscovering
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _isDiscovering ? Icons.radar : Icons.radar_outlined,
                  color: _isDiscovering ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isDiscovering
                      ? 'Discovering nearby devices... (${students.length} found)'
                      : 'Discovery stopped (${students.length} devices found)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search student or document...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? IconButton(
                  icon: const Icon(Icons.radar),
                  onPressed: _refreshDiscovery,
                  tooltip: 'Refresh Discovery',
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterStudents('');
                      },
                    ),
                    IconButton(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      icon: const Icon(Icons.radar),
                      onPressed: _refreshDiscovery,
                      tooltip: 'Refresh Discovery',
                    ),
                  ],
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _filterStudents,
            ),
          ),

          // List of students
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isDiscovering ? Icons.radar : Icons.devices,
                    size: 64,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isDiscovering
                        ? 'Searching for nearby devices...'
                        : students.isEmpty
                        ? 'No devices found\nTap the radar button to search'
                        : 'No students or docs match your search',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (!_isDiscovering && students.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startDiscovery,
                      icon: const Icon(Icons.radar),
                      label: const Text('Start Discovery'),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return StudentTile(
                  studentName: student["name"],
                  docList: List<String>.from(student["docs"] ?? []),
                  selectDoc: (val) {
                    debugPrint(
                        "Doc selected for ${student["name"]}: $val");
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}