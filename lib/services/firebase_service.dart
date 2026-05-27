import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/sos_message.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  late DatabaseReference _dbRef;

  Future<void> init() async {
    try {
      // Initialize Firebase (Stubbed for user to configure later with google-services.json)
      await Firebase.initializeApp();
      _dbRef = FirebaseDatabase.instance.ref('sos_messages');
      _isInitialized = true;
    } catch (e) {
      print("Firebase initialization error: $e");
    }
  }

  Future<bool> pushMessage(SosMessage message) async {
    if (!_isInitialized) {
      print("Firebase not initialized.");
      return false;
    }

    // Explicit internet check as per requirement
    bool hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      print("No internet connection available. Cannot push to Firebase.");
      return false;
    }

    try {
      await _dbRef.child(message.id).set(message.toMap());
      return true;
    } catch (e) {
      print("Failed to push message to Firebase: $e");
      return false;
    }
  }
}
