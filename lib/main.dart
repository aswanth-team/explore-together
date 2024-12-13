import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin/screens/admin_screen.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'user/screens/user_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check user authentication and determine the home screen
  Widget home;
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Fetch user details from Firestore to determine user type
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: user.email)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      home = AdminScreen(); // Redirect to AdminScreen if user is admin
    } else {
      home = UserScreen(); // Redirect to UserScreen for regular users
    }
  } else {
    home = LoginScreen(); // Redirect to LoginScreen if no user is logged in
  }

  runApp(MaterialApp(
    home: home,
    debugShowCheckedModeBanner: false,
  ));
}
