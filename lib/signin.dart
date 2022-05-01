import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learn_what_is_stream/app_service.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final app = MyAppService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pw = TextEditingController();

  String _errorMessage = '';

  Future<void> signInOrSignUp() async {
    try {
      await app.signIn(_email.text, _pw.text);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('ユーザーが見つからなかったので登録します。');
        await app.signUp(_email.text, _pw.text);
      } else if (e.code == 'wrong-password') {
        setState(() => _errorMessage = 'パスワードが間違っています。');
      } else {
        setState(() => _errorMessage = e.code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AlertDialog(
      title: const FittedBox(child: Text('ログイン/ユーザー登録', maxLines: 1)),
      content: SizedBox(
        width: size.width,
        height: size.height * .25,
        child: Column(
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            Row(children: [
              const Text('email:'),
              Expanded(
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ]),
            Row(children: [
              const Text('PW:'),
              Expanded(
                child: TextFormField(controller: _pw, obscureText: true),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: signInOrSignUp, child: const Text('I\'m ready')),
      ],
    );
  }
}
