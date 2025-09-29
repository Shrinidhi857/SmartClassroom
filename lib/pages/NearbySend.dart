import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nearby_connections/nearby_connections.dart' as nc;

class NearbysendPage extends StatefulWidget {
  const NearbysendPage({super.key});

  @override
  State<NearbysendPage> createState() => _NearbysendPageState();
}

class _NearbysendPageState extends State<NearbysendPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Dynamic data - discovered nearby receivers
  final List<Map<String, dynamic>> nearbyReceivers = [];

  // filtered view shown in the list
  List<Map<String, dynamic>> filteredReceivers = [];

  // Store selected files and user info
  final List<String> selectedFiles = [];
  String userName = "";

  // Advertising state
  bool _isAdvertising = false;
  final Set<String> _connectedEndpoints = {};

  @override
  void initState() {
    super.initState();
    filteredReceivers = List<Map<String, dynamic>>.from(nearbyReceivers);
    _searchController.addListener(() => _filterReceivers(_searchController.text));
    _showNameDialog();
  }

  void _showNameDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Enter Your Name'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveName(),
          ),
          actions: [
            TextButton(
              onPressed: _saveName,
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    });
  }

  void _saveName() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        userName = _nameController.text.trim();
      });
      Navigator.of(context).pop();
      _startAdvertising();
    }
  }

  Future<void> _startAdvertising() async {
    if (_isAdvertising || userName.isEmpty) return;

    setState(() {
      _isAdvertising = true;
    });

    try {
      await nc.Nearby().startAdvertising(
        userName,                     // 1st positional: endpointName
        nc.Strategy.P2P_CLUSTER,      // 2nd positional: Strategy
        serviceId: "com.example.my_nearby_service",   // ✅ must be named
        onConnectionInitiated: (endpointId, info) {
          debugPrint("Connection initiated with: ${info.endpointName}");

          nc.Nearby().acceptConnection(
            endpointId,
            onPayLoadRecieved: (endid, payload) {
              debugPrint("Received payload from $endid, type: ${payload.type}");
              if (payload.type == nc.PayloadType.BYTES) {
                String data = utf8.decode(payload.bytes!);
                debugPrint("Data received: $data");
              }
            },
            onPayloadTransferUpdate: (endid, update) {
              debugPrint("Transfer update from $endid: ${update.status}");
            },
          );
        },
        onConnectionResult: (endpointId, status) {
          debugPrint("Connection result for $endpointId: $status");
          if (status == nc.Status.CONNECTED) {
            _connectedEndpoints.add(endpointId);
            _addDiscoveredReceiver(endpointId, "Receiver_${endpointId.substring(0, 6)}");
          }
        },
        onDisconnected: (endpointId) {
          debugPrint("Disconnected: $endpointId");
          _connectedEndpoints.remove(endpointId);
          _removeDiscoveredReceiver(endpointId);
        },
      );


    } catch (e) {
      debugPrint("Error starting advertising: $e");
      setState(() {
        _isAdvertising = false;
      });
    }
  }


  Future<void> _stopAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await nc.Nearby().stopAdvertising();
      setState(() {
        _isAdvertising = false;
      });
      debugPrint("Stopped advertising");
    } catch (e) {
      debugPrint("Error stopping advertising: $e");
    }
  }



  void _addDiscoveredReceiver(String endpointId, String receiverName) {
    setState(() {
      // Check if receiver already exists
      final existingIndex = nearbyReceivers.indexWhere(
              (receiver) => receiver["endpointId"] == endpointId
      );

      if (existingIndex == -1) {
        nearbyReceivers.add({
          "name": receiverName,
          "endpointId": endpointId,
          "status": "Connected",
          "docs": selectedFiles.map((path) => path.split('/').last).toList(),
        });
        _filterReceivers(_searchController.text);
      }
    });
  }

  void _removeDiscoveredReceiver(String endpointId) {
    setState(() {
      nearbyReceivers.removeWhere((receiver) => receiver["endpointId"] == endpointId);
      _filterReceivers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _stopAdvertising();
    nc.Nearby().stopAllEndpoints();
    super.dispose();
  }

  void _filterReceivers(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredReceivers = List<Map<String, dynamic>>.from(nearbyReceivers);
      } else {
        filteredReceivers = nearbyReceivers.where((receiver) {
          final name = (receiver['name']?.toString() ?? '').toLowerCase();
          final status = (receiver['status']?.toString() ?? '').toLowerCase();

          final nameMatches = name.contains(query);
          final statusMatches = status.contains(query);
          return nameMatches || statusMatches;
        }).toList();
      }
    });

    debugPrint('Search "$query" -> ${filteredReceivers.length} result(s)');
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        selectedFiles.clear();
        selectedFiles.addAll(
            result.files
                .where((file) => file.path != null)
                .map((file) => file.path!)
        );
      });

      // Update docs for existing receivers
      for (var receiver in nearbyReceivers) {
        receiver["docs"] = selectedFiles.map((path) => path.split('/').last).toList();
      }

      debugPrint("Files selected: ${selectedFiles.length}");
    }
  }

  Future<void> _sendToReceiver(String endpointId, String receiverName) async {
    if (selectedFiles.isEmpty) {
      _showSnackBar("Please select files first");
      return;
    }

    try {
      // Create payload with user info and file list
      final payload = {
        "name": userName,
        "docs": selectedFiles.map((path) => path.split('/').last).toList(),
        "timestamp": DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(payload);
      final bytes = utf8.encode(jsonString);

      await nc.Nearby().sendBytesPayload(endpointId, bytes);

      _showSnackBar("Sent file list to $receiverName");
      debugPrint("Sent payload to $endpointId: $jsonString");

    } catch (e) {
      debugPrint("Error sending to $endpointId: $e");
      _showSnackBar("Failed to send to $receiverName");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restartAdvertising() {
    _stopAdvertising().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _startAdvertising();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          "📤 Manual Sender${userName.isNotEmpty ? ' - $userName' : ''}",
          style: GoogleFonts.roboto(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isAdvertising ? Icons.stop : Icons.wifi_tethering,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: _isAdvertising ? _stopAdvertising : _restartAdvertising,
            tooltip: _isAdvertising ? 'Stop Advertising' : 'Start Advertising',
          ),
        ],
      ),
      body: Column(
        children: [
          // Advertising status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isAdvertising
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _isAdvertising ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  color: _isAdvertising ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAdvertising
                      ? 'Advertising as "$userName" (${nearbyReceivers.length} receivers found)'
                      : 'Not advertising - tap the wifi icon to start',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
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
                hintText: "Search receivers...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? IconButton(
                  icon: const Icon(Icons.wifi_tethering),
                  onPressed: _restartAdvertising,
                  tooltip: 'Restart Advertising',
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterReceivers('');
                      },
                    ),
                    IconButton(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      icon: const Icon(Icons.wifi_tethering),
                      onPressed: _restartAdvertising,
                      tooltip: 'Restart Advertising',
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
              onSubmitted: _filterReceivers,
            ),
          ),

          // File picker widget
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon:  Icon(Icons.attach_file,color:Theme.of(context).colorScheme.inversePrimary,),
                  label: Text(
                    selectedFiles.isEmpty ? "Select Files to Send" : "Change Files (${selectedFiles.length})",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      color:Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Selected files (${selectedFiles.length}):",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...selectedFiles.take(3).map((path) => Text(
                          "• ${path.split('/').last}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )),
                        if (selectedFiles.length > 3)
                          Text(
                            "• ... and ${selectedFiles.length - 3} more",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // List of nearby receivers
          Expanded(
            child: filteredReceivers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAdvertising ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isAdvertising
                        ? 'Waiting for receivers to connect...'
                        : nearbyReceivers.isEmpty
                        ? 'Start advertising to find receivers'
                        : 'No receivers match your search',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (!_isAdvertising) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startAdvertising,
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('Start Advertising'),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredReceivers.length,
              itemBuilder: (context, index) {
                final receiver = filteredReceivers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(receiver["name"] ?? "Unknown Receiver"),
                    subtitle: Text("Status: ${receiver["status"]}"),
                    trailing: ElevatedButton(
                      onPressed: selectedFiles.isEmpty
                          ? null
                          : () => _sendToReceiver(
                          receiver["endpointId"],
                          receiver["name"]
                      ),
                      child: const Text("Send"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}