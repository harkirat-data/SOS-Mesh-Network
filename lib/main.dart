import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/ble_mesh_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  final bleMeshService = BleMeshService();
  await bleMeshService.init();

  final firebaseService = FirebaseService();
  await firebaseService.init();

  // Set up Gateway logic listener globally
  bleMeshService.messageStream.listen((message) async {
    final prefs = await SharedPreferences.getInstance();
    final nodeMode = prefs.getString('nodeMode') ?? 'Victim';
    
    if (nodeMode == 'Gateway') {
      bleMeshService.logStatus("Gateway Mode: Attempting to upload to Firebase...");
      bool success = await firebaseService.pushMessage(message);
      if (success) {
        bleMeshService.logStatus("Successfully uploaded message (ID: ${message.id}) to Firebase.");
      } else {
        bleMeshService.logStatus("Failed to upload message to Firebase.");
      }
    }
  });

  runApp(const MeshSosApp());
}

class MeshSosApp extends StatelessWidget {
  const MeshSosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Mesh App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
