import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class NearbyServicePage extends StatefulWidget {
  const NearbyServicePage({Key? key}) : super(key: key);

  @override
  State<NearbyServicePage> createState() => _NearbyServicePageState();
}

class DiscoveredDevice {
  final String endpointId;
  final String endpointName;
  bool connected;

  DiscoveredDevice({
    required this.endpointId,
    required this.endpointName,
    this.connected = false,
  });
}

class _NearbyServicePageState extends State<NearbyServicePage> {
  final Strategy strategy = Strategy.P2P_CLUSTER; // or P2P_STAR depending on use-case
  final String serviceId = "com.example.my_nearby_service"; // change to your unique service id
  final String userName = "User_${DateTime.now().millisecondsSinceEpoch % 1000}";

  Nearby nearby = Nearby();
  Map<String, DiscoveredDevice> discoveredDevices = {};
  Map<String, bool> acceptingConnection = {};

  StreamController<String> logController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    // optionally check and request permissions upfront
    _ensurePermissions();
    _setupNearbyCallbacks(); // set up global callbacks
  }

  @override
  void dispose() {
    logController.close();
    super.dispose();
  }

  void _log(String s) {
    debugPrint(s);
    logController.add(s);
  }

  Future<void> _ensurePermissions() async {
    // Request runtime permissions that Nearby requires
    final permissions = <Permission>[
    Permission.locationWhenInUse,  // covers fine location
    Permission.location,
    Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.storage,
      Permission.nearbyWifiDevices,

    ];

    for (final p in permissions) {
      if (await p.isDenied) {
        await p.request();
      }
    }
  }

  void _setupNearbyCallbacks() {

  }

  // ---------- ADVERTISE ----------
  Future<void> startAdvertising() async {
    _log("Starting Advertising as $userName");
    try {
      bool result = await nearby.startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          _log("onConnectionResult($id) -> $status");
          setState(() {
            discoveredDevices[id]?.connected = (status == Status.CONNECTED);
          });
        },
        onDisconnected: (id) {
          _log("onDisconnected: $id");
          setState(() {
            discoveredDevices[id]?.connected = false;
          });
        },
        serviceId: serviceId,
      );
      _log("Advertising started: $result");
    } catch (e) {
      _log("startAdvertising error: $e");
    }
  }

  Future<void> stopAdvertising() async {
    await nearby.stopAdvertising();
    _log("Stopped advertising");
  }

  // ---------- DISCOVERY ----------
  Future<void> startDiscovery() async {
    _log("Starting Discovery");
    try {
      bool result = await nearby.startDiscovery(
        serviceId,
        strategy,
        onEndpointFound: (id, name, serviceIdFound) {
          _log("Endpoint found: $name ($id) serviceId: $serviceIdFound");
          setState(() {
            discoveredDevices[id] = DiscoveredDevice(
              endpointId: id,
              endpointName: name,
              connected: false,
            );
          });
        },
        onEndpointLost: (id) {
          _log("Endpoint lost: $id");
          setState(() {
            discoveredDevices.remove(id);
          });
        },
      );
      _log("Discovery started: $result");
    } catch (e) {
      _log("startDiscovery error: $e");
    }
  }

  Future<void> stopDiscovery() async {
    await nearby.stopDiscovery();
    _log("Stopped discovery");
  }

  // ---------- CONNECTION FLOW ----------
  // When someone requests or we request connection, this is called
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _log("Connection initiated from ${info.endpointName} ($endpointId). AuthenticationToken: ${info.authenticationToken}");
    // Show accept/decline dialog
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Connection Request"),
          content: Text("${info.endpointName} wants to connect."),
          actions: [
            TextButton(
                onPressed: () async {
                  // Decline
                  await nearby.rejectConnection(endpointId);
                  _log("Rejected connection $endpointId");
                  Navigator.of(context).pop();
                },
                child: const Text("Reject")),
            TextButton(
                onPressed: () async {
                  // Accept
                  await nearby.acceptConnection(
                    endpointId,
                    onPayLoadRecieved: (endid, payload) {
                      _handlePayload(endid, payload);
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      _log("Payload transfer update: ${payloadTransferUpdate.status} for ${endid}");
                    },
                  );
                  _log("Accepted connection $endpointId");
                  setState(() {
                    discoveredDevices[endpointId]?.connected = true;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text("Accept")),
          ],
        );
      },
    );
  }

  Future<void> requestConnection(String endpointId) async {
    _log("Requesting connection to $endpointId");
    try {
      await nearby.requestConnection(
        userName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          _log("Request -> onConnectionResult($id): $status");
          setState(() {
            discoveredDevices[id]?.connected = status == Status.CONNECTED;
          });
        },
        onDisconnected: (id) {
          _log("Request -> onDisconnected($id)");
          setState(() {
            discoveredDevices[id]?.connected = false;
          });
        },
      );
    } catch (e) {
      _log("requestConnection error: $e");
    }
  }

  Future<void> disconnectFrom(String endpointId) async {
    await nearby.disconnectFromEndpoint(endpointId);
    setState(() {
      discoveredDevices[endpointId]?.connected = false;
    });
    _log("Disconnected from $endpointId");
  }

  // ---------- SENDING DATA ----------
  Future<void> sendBytes(String endpointId, String message) async {
    final bytes = Uint8List.fromList(message.codeUnits); // directly Uint8List
    _log("Sending bytes to $endpointId (${bytes.length} bytes)");

    try {
      await nearby.sendBytesPayload(endpointId, bytes); // send Uint8List directly
      _log("Sent bytes to $endpointId");
    } catch (e) {
      _log("sendBytes error: $e");
    }
  }


  Future<void> sendFile(String endpointId) async {
    // Pick file
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null) {
      _log("File picking canceled");
      return;
    }
    final filePath = result.files.single.path;
    if (filePath == null) {
      _log("Selected file path null");
      return;
    }
    _log("Sending file: $filePath to $endpointId");
    try {
      final payloadId = await nearby.sendFilePayload(endpointId, filePath);
      _log("Sent file payload id: $payloadId");
    } catch (e) {
      _log("sendFile error: $e");
    }
  }

  // ---------- RECEIVE HANDLING ----------
  Future<void> _handlePayload(String endpointId, Payload payload) async {
    _log("Received payload from $endpointId type: ${payload.type}");

    if (payload.type == PayloadType.BYTES) {
      final bytes = payload.bytes!;
      final text = String.fromCharCodes(bytes);
      _log("Received bytes: $text");
      // do something with the text, e.g., show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Message from ${endpointId.substring(0,6)}: $text")));
    } else if (payload.type == PayloadType.FILE) {
      final tempPath = payload.filePath;
      _log("Received file at temp path: $tempPath");
      // Move file to app directory or downloads
      try {
        final saved = await _saveReceivedFile(tempPath!);
        _log("Saved received file to $saved");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File saved: $saved")));
      } catch (e) {
        _log("Error saving received file: $e");
      }
    } else if (payload.type == PayloadType.STREAM) {
      _log("Received STREAM payload (not handled)");
      // You can handle streaming payloads here
    }
  }



  Future<String> _saveReceivedFile(String tempFilePath) async {
    final tempFile = File(tempFilePath);
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final dest = File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${tempFile.uri.pathSegments.last}");
    await tempFile.copy(dest.path);
    return dest.path;
  }

  // ---------- Utility UI actions ----------
  void _clearDevices() {
    setState(() {
      discoveredDevices.clear();
    });
  }

  // ---------- Simple UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Connections Demo"),
        actions: [
          IconButton(
            tooltip: "Clear list",
            icon: const Icon(Icons.clear_all),
            onPressed: _clearDevices,
          )
        ],
      ),
      body: Column(
        children: [
          _controlButtons(),
          const Divider(),
          _devicesList(),
          const Divider(),
          _logsWidget(),
        ],
      ),
    );
  }

  Widget _controlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.campaign),
            label: const Text("Start Advertise"),
            onPressed: startAdvertising,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.stop_circle),
            label: const Text("Stop Advertise"),
            onPressed: stopAdvertising,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text("Start Discovery"),
            onPressed: startDiscovery,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text("Stop Discovery"),
            onPressed: stopDiscovery,
          ),
        ],
      ),
    );
  }

  Widget _devicesList() {
    final items = discoveredDevices.values.toList();
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final dev = items[i];
          return ListTile(
            leading: CircleAvatar(child: Text(dev.endpointName.isNotEmpty ? dev.endpointName[0] : '?')),
            title: Text(dev.endpointName),
            subtitle: Text(dev.endpointId),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!dev.connected)
                  TextButton(
                    onPressed: () => requestConnection(dev.endpointId),
                    child: const Text("Connect"),
                  ),
                if (dev.connected) ...[
                  IconButton(
                    tooltip: "Send message",
                    icon: const Icon(Icons.send),
                    onPressed: () => _showSendMessageDialog(dev.endpointId),
                  ),
                  IconButton(
                    tooltip: "Send file",
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => sendFile(dev.endpointId),
                  ),
                  IconButton(
                    tooltip: "Disconnect",
                    icon: const Icon(Icons.link_off),
                    onPressed: () => disconnectFrom(dev.endpointId),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _logsWidget() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<String>(
        stream: logController.stream,
        builder: (context, snapshot) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.black12,
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                snapshot.data ?? "Logs will appear here...",
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSendMessageDialog(String endpointId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send Message"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Type a message"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                sendBytes(endpointId, text);
              }
              Navigator.of(context).pop();
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }
}
