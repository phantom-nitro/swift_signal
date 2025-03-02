// import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _userRole;
  
  // Getter for user role
  String? get userRole => _userRole;
  
  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
  
  // Get current user ID
  String? get userId => _auth.currentUser?.uid;
  
  // Sign up with email and password
  Future<void> signUp(String email, String password, String role) async {
    try {
      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Store user role in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Set the user role
      _userRole = role;
    } catch (e) {
      throw Exception('Failed to create account: ${e.toString()}');
    }
  }
  
  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      // Sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Fetch user role from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (userDoc.exists) {
        _userRole = userDoc.data()?['role'];
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _userRole = null;
  }
  
  // Check and load user role on app start
  Future<String?> loadUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _userRole = userDoc.data()?['role'];
        return _userRole;
      }
    }
    return null;
  }
}