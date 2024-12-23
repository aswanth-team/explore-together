import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'admin/screens/admin_screen.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'user/screens/user_screen.dart';

const apiKey = '-GEMINI API-';

Future<void> initializeServices() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('6ebc33e0-21f7-4380-867f-9a6c8c9220e9');
  OneSignal.Notifications.requestPermission(true);

  // Initialize Gemini
  Gemini.init(apiKey: apiKey);
}

Future<Widget> determineHomeScreen() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: user.email)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      return const AdminScreen();
    } else {
      return const UserScreen();
    }
  } else {
    return const LoginScreen();
  }
}

void main() async {
  await initializeServices();
  final homeScreen = await determineHomeScreen();

  runApp(MyApp(home: homeScreen));
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}
