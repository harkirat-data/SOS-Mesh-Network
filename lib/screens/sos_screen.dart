import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_message.dart';
import '../services/ble_mesh_service.dart';
import '../services/location_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final TextEditingController _nameController = TextEditingController();
  final BleMeshService _meshService = BleMeshService();
  final LocationService _locationService = LocationService();
  
  bool _useGps = true;
  double _manualLat = 0.0;
  double _manualLng = 0.0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
    });
  }

  Future<void> _sendSos() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());

    double lat = _manualLat;
    double lng = _manualLng;

    if (_useGps) {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get GPS. Using default/manual location.')),
        );
      }
    }

    final message = SosMessage(
      senderName: _nameController.text.trim(),
      lat: lat,
      lng: lng,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      hopCount: 5, // Default TTL
    );

    await _meshService.broadcastMessage(message);

    setState(() {
      _isSending = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS Message Broadcasted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use GPS Location'),
            value: _useGps,
            onChanged: (val) {
              setState(() {
                _useGps = val;
              });
            },
          ),
          if (!_useGps) ...[
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Manual Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _manualLat = double.tryParse(val) ?? 0.0,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Manual Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _manualLng = double.tryParse(val) ?? 0.0,
            ),
          ],
          const Spacer(),
          ElevatedButton(
            onPressed: _isSending ? null : _sendSos,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: _isSending
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SEND SOS',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
