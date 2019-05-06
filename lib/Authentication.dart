import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

abstract class AuthImplementation {

  Future<String> signIn(String email, String password);
  Future<String> signUp(String email, String password);
  Future<String> getCurrentUser();
  Future<String> getCurrentUser_username();
  Future<void> signOut();

}

class Auth implements AuthImplementation {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String> signIn(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return user.uid;
  }

  Future<String> signUp(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    return user.uid;
  }

  Future<String> getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.uid;
  }

  Future<String> getCurrentUser_username() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    DatabaseReference dbRef = FirebaseDatabase.instance.reference().child("Users");
    dbRef.onValue.listen((e) {
      var KEYS = e.snapshot.value.keys;
      var DATA = e.snapshot.value;

      for(var individualKey in KEYS) {
        if (DATA[individualKey]['userId'] == user.uid) {
          return DATA[individualKey]['username'];
        }
      }
    });
  }

  Future<void> signOut() async {
    _firebaseAuth.signOut();
  }
}
