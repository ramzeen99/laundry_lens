import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> signIn(
      String email,
      String password,
      ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    final userDoc =
    await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      throw Exception('Utilisateur non trouvé dans Firestore');
    }

    return userDoc.data()!;
  }
}
