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

  Widget home;
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {

    final adminSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: user.email)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      home = AdminScreen(); 
    } else {
      home = UserScreen(); 
    }
  } else {
    home = LoginScreen();
  }

  runApp(MaterialApp(
    home: home,
    debugShowCheckedModeBanner: false,
  ));
}
