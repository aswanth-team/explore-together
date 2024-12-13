import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPostServices {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> deletePost(String postId) async {
    try {
      await firestore.collection('post').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }
}
