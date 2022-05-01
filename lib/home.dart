import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learn_what_is_stream/app_service.dart';
import 'package:learn_what_is_stream/signin.dart';
import 'package:learn_what_is_stream/utils.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final app = MyAppService();
  Stream<bool>? _notificationStream;
  String uid = '';
  int _counter = 0;

  void _signIn() async {
    await showDialog<UserCredential>(
      context: context,
      builder: (BuildContext context) => const SignIn(),
    );
  }

  void _signOut() async => await auth.signOut();

  void _incrementCounter() async {
    setState(() => _counter++);

    if (auth.currentUser != null) {
      await app.increment(uid);
      await app.sendUpdates(uid);
    }
  }

  Future<void> _updateCounter({GetOptions? option}) async {
    Document _valueData = await app.readsDoc(option: option);
    if (_counter > _valueData['counter']) {
      print('サインインしてない時に押下しとったやろ');
      await counterRef.update({'counter': _counter});
    } else {
      setState(() => _counter = _valueData['counter']);
    }

    if (option == null) app.resetUpdate(uid);
  }

  @override
  void initState() {
    super.initState();
    _updateCounter(option: const GetOptions(source: Source.cache));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          uid = auth.currentUser!.uid;
          _notificationStream = firestore
              .collection('users')
              .doc(uid)
              .counterNotification
              .snapshots()
              .map<bool>((event) {
            if (!event.exists) return false;
            return event['updated'] as bool? ?? false;
          });
        }

        return Scaffold(
          appBar: AppBar(
            leading: auth.currentUser != null
                ? IconButton(
                    onPressed: _signOut,
                    icon: const Icon(Icons.scuba_diving_outlined),
                  )
                : null,
            actions: [
              if (auth.currentUser == null)
                TextButton(
                  onPressed: _signIn,
                  style: TextButton.styleFrom(primary: Colors.yellowAccent),
                  child: const Text('Sign In'),
                ),
              if (auth.currentUser != null) Text(auth.currentUser!.uid),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_notificationStream != null)
                StreamBuilder<bool>(
                    stream: _notificationStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          waiting(snapshot) ||
                          snapshot.data != true) {
                        return Container();
                      }
                      return FloatingActionButton(
                        onPressed: _updateCounter,
                        tooltip: 'Update',
                        child: const Icon(Icons.rotate_right),
                      );
                    }),
              FloatingActionButton(
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }
}
