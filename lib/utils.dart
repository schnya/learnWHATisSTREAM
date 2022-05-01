import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

typedef Document = Map<String, dynamic>;

final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;
final FirebaseFunctions functions = FirebaseFunctions.instance;

late final DocumentReference<Document> counterRef =
    firestore.collection('counter').doc('hoge');
late final DocumentReference<Document> userRef =
    firestore.collection('users').doc(auth.currentUser!.uid);

extension Notifications on DocumentReference<Document> {
  DocumentReference<Document> get counterNotification =>
      collection('notifications').doc('hoge');
}

bool waiting(AsyncSnapshot snapshot) =>
    snapshot.connectionState == ConnectionState.waiting;
