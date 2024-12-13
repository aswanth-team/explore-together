import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserAuthServices {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> userRegisterInFirebase({
    required BuildContext context,
    required String username,
    required String fullname,
    required String dob,
    required String gender,
    required String phoneno,
    required String aadharno,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String userUid = userCredential.user?.uid ?? '';
      await firestore.collection('user').doc(userUid).set({
        'username': username,
        'phoneno': phoneno,
        'email': email,
        'dob': dob,
        'gender': gender,
        'fullname': fullname,
        'aadharno': aadharno,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Successful for $username'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Registration Unsuccessful for $username: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<String>> checkIfUserExists({
    required String username,
    required String email,
    required String mobile,
    required String aadharno,
  }) async {
    try {
      List<String> conflicts = [];

      final usernameSnapshot = await firestore
          .collection('user')
          .where('username', isEqualTo: username)
          .get();
      if (usernameSnapshot.docs.isNotEmpty) {
        conflicts.add("Username");
      }

      final emailSnapshot = await firestore
          .collection('user')
          .where('email', isEqualTo: email)
          .get();
      if (emailSnapshot.docs.isNotEmpty) {
        conflicts.add("Email");
      }

      final mobileSnapshot = await firestore
          .collection('user')
          .where('phoneno', isEqualTo: mobile)
          .get();
      if (mobileSnapshot.docs.isNotEmpty) {
        conflicts.add("Mobile number");
      }

      final aadharSnapshot = await firestore
          .collection('user')
          .where('aadharno', isEqualTo: aadharno)
          .get();
      if (aadharSnapshot.docs.isNotEmpty) {
        conflicts.add("Aadhar number");
      }

      return conflicts;
    } catch (e) {
      return ["Error checking user data"];
    }
  }

  Future<String?> checkUserExistence(String identifier) async {
    try {
      final QuerySnapshot userSnapshot = await firestore
          .collection('user')
          .where('username', isEqualTo: identifier)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.id; // Return user ID
      }

      final QuerySnapshot emailSnapshot = await firestore
          .collection('user')
          .where('email', isEqualTo: identifier)
          .limit(1)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        return emailSnapshot.docs.first.id; // Return user ID
      }

      final QuerySnapshot phoneSnapshot = await firestore
          .collection('user')
          .where('phoneno', isEqualTo: identifier)
          .limit(1)
          .get();

      if (phoneSnapshot.docs.isNotEmpty) {
        return phoneSnapshot.docs.first.id; // Return user ID
      }

      return null; // No user found
    } catch (e) {
      throw Exception('Error checking user existence: ${e.toString()}');
    }
  }

  Future<void> updatePassword(String userId, String newPassword) async {
    try {
      await firestore.collection('user').doc(userId).update({
        'password': newPassword,
      });
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }
}
