import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ble_mesh_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _nodeMode = 'Victim'; // 'Victim', 'Relay', 'Gateway'
  final BleMeshService _meshService = BleMeshService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nodeMode = prefs.getString('nodeMode') ?? 'Victim';
    });
    _applyModeLogic(_nodeMode);
  }

  Future<void> _saveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nodeMode', mode);
    setState(() {
      _nodeMode = mode;
    });
    _applyModeLogic(mode);
  }

  void _applyModeLogic(String mode) {
    if (mode == 'Victim') {
      _meshService.stopScanning();
      _meshService.logStatus("Mode changed to Victim (No passive scanning)");
    } else if (mode == 'Relay' || mode == 'Gateway') {
      _meshService.startScanning();
      _meshService.logStatus("Mode changed to $mode (Scanning active)");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Node Mode',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: const Text('Victim'),
            subtitle: const Text('Can send SOS. Does not relay others.'),
            value: 'Victim',
            groupValue: _nodeMode,
            onChanged: (val) => _saveMode(val!),
          ),
          RadioListTile<String>(
            title: const Text('Relay'),
            subtitle: const Text('Passively scans and forwards SOS messages.'),
            value: 'Relay',
            groupValue: _nodeMode,
            onChanged: (val) => _saveMode(val!),
          ),
          RadioListTile<String>(
            title: const Text('Gateway'),
            subtitle: const Text('Relays messages and pushes them to Firebase.'),
            value: 'Gateway',
            groupValue: _nodeMode,
            onChanged: (val) => _saveMode(val!),
          ),
        ],
      ),
    );
  }
}
