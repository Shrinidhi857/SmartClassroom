import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart' as nc;

class NearbyAutoManager {
  final String userName;
  final List<String> docs;
  final ValueChanged<Map<String, dynamic>> onPeerUpdated; // callback when peers update

  bool _advertising = false;
  bool _discovering = false;
  final Set<String> _connectedEndpoints = {};
  final Map<String, List<String>> _peerDocs = {}; // endpointId -> docs

  NearbyAutoManager({
    required this.userName,
    required this.docs,
    required this.onPeerUpdated,
  });

  Future<void> start() async {
    await _startAdvertising();
    await _startDiscovery();
  }

  Future<void> stop() async {
    if (_advertising) {
      await nc.Nearby().stopAdvertising();
      _advertising = false;
    }
    if (_discovering) {
      await nc.Nearby().stopDiscovery();
      _discovering = false;
    }
    await nc.Nearby().stopAllEndpoints();
  }

  Future<void> _startAdvertising() async {
    if (_advertising) return;
    _advertising = true;

    await nc.Nearby().startAdvertising(
      userName,
      nc.Strategy.P2P_CLUSTER,
      serviceId: "com.example.my_nearby_service",
      onConnectionInitiated: (endpointId, info) {
        debugPrint("Incoming connection from ${info.endpointName}");
        nc.Nearby().acceptConnection(
          endpointId,
          onPayLoadRecieved: (endid, payload) {
            if (payload.type == nc.PayloadType.BYTES) {
              final data = utf8.decode(payload.bytes!);
              debugPrint("Received from $endid: $data");
            }
          },
          onPayloadTransferUpdate: (endid, update) {
            debugPrint("Transfer update: $update");
          },
        );
      },
      onConnectionResult: (endpointId, status) {
        if (status == nc.Status.CONNECTED) {
          _connectedEndpoints.add(endpointId);
          // Immediately send my docs list
          _sendDocs(endpointId);
        }
      },
      onDisconnected: (endpointId) {
        _connectedEndpoints.remove(endpointId);
        _peerDocs.remove(endpointId);
        _notifyPeers();
      },
    );
  }

  Future<void> _startDiscovery() async {
    if (_discovering) return;
    _discovering = true;

    await nc.Nearby().startDiscovery(
      userName,
      nc.Strategy.P2P_CLUSTER,
      serviceId: "com.example.my_nearby_service",
      onEndpointFound: (endpointId, name, serviceId) {
        debugPrint("Found $name [$endpointId]");
        nc.Nearby().requestConnection(
          userName,
          endpointId,
          onConnectionInitiated: (endid, info) {
            nc.Nearby().acceptConnection(
              endid,
              onPayLoadRecieved: (id, payload) {
                if (payload.type == nc.PayloadType.BYTES) {
                  final data = utf8.decode(payload.bytes!);
                  final jsonMap = jsonDecode(data);
                  _peerDocs[id] = List<String>.from(jsonMap['docs'] ?? []);
                  _notifyPeers();
                }
              },
              onPayloadTransferUpdate: (id, update) {},
            );
          },
          onConnectionResult: (endid, status) {
            if (status == nc.Status.CONNECTED) {
              _connectedEndpoints.add(endid);
              // Ask for their docs (trigger them to send)
              _sendRequestForDocs(endid);
            }
          },
          onDisconnected: (endid) {
            _connectedEndpoints.remove(endid);
            _peerDocs.remove(endid);
            _notifyPeers();
          },
        );
      },
      onEndpointLost: (endpointId) {
        debugPrint("Lost endpoint: $endpointId");
        _peerDocs.remove(endpointId);
        _notifyPeers();
      },
    );
  }

  void _sendDocs(String endpointId) {
    final payload = {
      "name": userName,
      "docs": docs,
      "timestamp": DateTime.now().toIso8601String(),
    };
    final bytes = utf8.encode(jsonEncode(payload));
    nc.Nearby().sendBytesPayload(endpointId, bytes);
  }

  void _sendRequestForDocs(String endpointId) {
    final payload = {"request": "docs"};
    final bytes = utf8.encode(jsonEncode(payload));
    nc.Nearby().sendBytesPayload(endpointId, bytes);
  }

  void _notifyPeers() {
    onPeerUpdated(_peerDocs);
  }
}
