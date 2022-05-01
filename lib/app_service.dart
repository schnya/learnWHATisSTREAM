import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'utils.dart';

class MyAppService {
  Future<Document> readsDoc({GetOptions? option}) async {
    if (option == null) print('🔥 Connected - _readsDoc');

    try {
      Document _valueData = await counterRef
          .get(option)
          .then<Document>((value) => value.data() ?? {});
      if (!_valueData.containsKey('counter')) {
        _valueData['counter'] = 0;
        await counterRef.set({'counter': 0});
      }

      return _valueData;
    } on FirebaseException catch (e) {
      print(e);
      return {};
    }
  }

  Future<void> increment(String uid) {
    return counterRef.update({
      'counter': FieldValue.increment(1),
      'users': FieldValue.arrayUnion([uid]),
    }).then((value) => print('🔥 Connected - _incrementCounter'));
  }

  Future<void> callHttps() async {
    final https = functions.httpsCallable('helloWorld');
    try {
      var result = await https();
      print(result.data.toString());
    } on FirebaseFunctionsException catch (e) {
      print(e.code);
      print('👨‍👧‍👦 $e');
    }
  }

  Future<void> sendUpdates(String uid) async {
    // await callHttps();

    Document _valueData = await readsDoc();
    if (_valueData.containsKey('users')) {
      final WriteBatch batch = firestore.batch();

      final List tmp = _valueData['users'] as List;
      final List<String> users = tmp.whereType<String>().toList();
      // print(users);

      firestore.collection('users').get().then((querySnapshot) {
        for (var element in querySnapshot.docs) {
          // print('🤮 ${element.id}');
          if (users.contains(element.id) && element.id != uid) {
            // 1unit でまとめてやってくれる。安い？？そういうわけじゃない？
            batch.set(
              firestore.collection('users').doc(element.id).counterNotification,
              {'updated': true},
            );
          }
        }

        return batch.commit();
      });
    }
  }

  Future<void> resetUpdate(String uid) {
    // updateの前にgetして、falseかどうか確認した方が安く済む？
    // trueのケースが多いならせん方がマシ。
    return userRef.counterNotification.update({'updated': false});
  }

  Future<void> signIn(String email, String password) async {
    await auth
        .signInWithEmailAndPassword(email: email, password: password)
        .then((value) async {
      print('Signed in🧶');
      userRef.get().then((value) {
        if (!value.exists) userRef.set({'email': email});
      });
    });
  }

  Future<void> signUp(String email, String password) async {
    try {
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .set({'email': email})
          .then((value) => print('Created User📬'))
          .catchError((e) => throw e);
    } on FirebaseAuthException catch (e) {
      print(e.code);
    } on FirebaseException catch (e) {
      print(e.code);
      print('うまくいきませんでした: $e');
    }
  }
}
