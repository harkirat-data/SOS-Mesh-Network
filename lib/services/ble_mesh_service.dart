import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sos_message.dart';

class BleMeshService {
  static final BleMeshService _instance = BleMeshService._internal();
  factory BleMeshService() => _instance;
  BleMeshService._internal();

  // MethodChannel for native BLE advertising
  static const _advertiserChannel =
      MethodChannel('com.example.bluetooth_messaging/ble_advertiser');

  final int manufacturerId = 0xFFFF;
  final String serviceUuid = "0000FFFF-0000-1000-8000-00805F9B34FB";

  final Set<String> _seenMessageIds = {};

  // Stream to notify UI of status updates
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Stream to notify Gateway of new messages to upload
  final StreamController<SosMessage> _messageController =
      StreamController<SosMessage>.broadcast();
  Stream<SosMessage> get messageStream => _messageController.stream;

  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  void logStatus(String msg) {
    _statusController.add(msg);
  }

  Future<void> init() async {
    logStatus("BLE Mesh Service initialized.");
  }

  // ── Scanning (Central role via flutter_blue_plus) ──

  Future<void> startScanning() async {
    if (_isScanning) return;
    _isScanning = true;
    logStatus("Started scanning for mesh nodes...");

    await FlutterBluePlus.startScan(
      withServices: [Guid(serviceUuid)],
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final mfgData = r.advertisementData.manufacturerData;
        if (mfgData.containsKey(manufacturerId)) {
          final data = mfgData[manufacturerId]!;
          _handleIncomingData(data);
        }
      }
    });
  }

  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    logStatus("Stopped scanning.");
  }

  void _handleIncomingData(List<int> data) {
    try {
      final jsonStr = utf8.decode(data);
      final msg = SosMessage.fromJson(jsonStr);

      if (!_seenMessageIds.contains(msg.id)) {
        _seenMessageIds.add(msg.id);
        logStatus(
            "Received new SOS from ${msg.senderName} (ID: ${msg.id.substring(0, 8)}...)");

        // Notify gateway listener
        _messageController.add(msg);

        // Relay logic
        if (msg.hopCount > 0) {
          final relayedMsg = msg.copyWith(hopCount: msg.hopCount - 1);
          logStatus("Relaying message... (TTL: ${relayedMsg.hopCount})");
          broadcastMessage(relayedMsg);
        } else {
          logStatus("Message TTL is 0. Dropping.");
        }
      }
    } catch (e) {
      // Failed to parse — likely partial or corrupted data, silently ignore
    }
  }

  // ── Broadcasting (Peripheral role via native MethodChannel) ──

  Future<void> broadcastMessage(SosMessage msg) async {
    _seenMessageIds.add(msg.id); // Don't re-process our own message

    final payload = utf8.encode(msg.toJson());

    // BLE manufacturer data limit is ~24 bytes in a scan response.
    // For messages exceeding this, we truncate or compress.
    // In a production app, you'd use a chunked GATT approach.
    if (payload.length > 24) {
      logStatus(
          "Warning: Payload (${payload.length} bytes) exceeds BLE advert limit. Truncating name for broadcast.");
      // Create a compact version with a shorter name
      final compactMsg = msg.copyWith(
          senderName: msg.senderName.length > 4
              ? msg.senderName.substring(0, 4)
              : msg.senderName);
      final compactPayload = utf8.encode(compactMsg.toJson());
      await _startNativeAdvertising(compactPayload, msg.id);
    } else {
      await _startNativeAdvertising(payload, msg.id);
    }
  }

  Future<void> _startNativeAdvertising(List<int> payload, String msgId) async {
    try {
      await _advertiserChannel.invokeMethod('startAdvertising', {
        'serviceUuid': serviceUuid,
        'payload': Uint8List.fromList(payload),
      });
      logStatus("Broadcasting message (ID: ${msgId.substring(0, 8)}...)");

      // Automatically stop advertising after 10 seconds
      Future.delayed(const Duration(seconds: 10), () async {
        await _stopNativeAdvertising();
        logStatus(
            "Stopped broadcasting message (ID: ${msgId.substring(0, 8)}...)");
      });
    } on PlatformException catch (e) {
      logStatus("Advertising error: ${e.message}");
    }
  }

  Future<void> _stopNativeAdvertising() async {
    try {
      await _advertiserChannel.invokeMethod('stopAdvertising');
    } on PlatformException catch (e) {
      logStatus("Stop advertising error: ${e.message}");
    }
  }
}