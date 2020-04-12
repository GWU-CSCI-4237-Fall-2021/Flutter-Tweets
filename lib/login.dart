import 'dart:math';

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final String title;

  LoginScreen({Key key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  var buttonsEnabled = false;

  var loadingShown = false;

  final emailTextController = TextEditingController();

  final passwordTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    emailTextController.addListener(updateButtonState);
    passwordTextController.addListener(updateButtonState);
  }

  @override
  void dispose() {
    emailTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }

  void updateButtonState() {
    final enabled = emailTextController.text.trim().isNotEmpty && passwordTextController.text.trim().isNotEmpty;
    setState(() {
      buttonsEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(
      "Login",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );

    final email = Container(
        width: 250,
        margin: EdgeInsets.only(top: 8.0),
        child: TextField(
          controller: emailTextController,
          decoration: InputDecoration(
            hintText: "Email",
          ),
        ));

    final password = Container(
        width: 250,
        margin: EdgeInsets.only(top: 8.0),
        child: TextField(
          obscureText: true,
          controller: passwordTextController,
          decoration: InputDecoration(
            hintText: "Password",
          ),
        ));

    final login = Container(
        margin: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
        child: RaisedButton(
            onPressed: buttonsEnabled ? () {
              setState(() {
                loadingShown = true;
              });
            } : null,
            child: SizedBox(
                width: double.infinity,
                child: Center(
                    child: Text('LOGIN')
                )
            )
        )
    );

    final signUp = Container(
        margin: EdgeInsets.symmetric(horizontal: 24.0),
        child: RaisedButton(
            onPressed: buttonsEnabled ? () {} : null,
            child: SizedBox(
                width: double.infinity,
                child: Center(
                    child: Text('SIGN UP')
                )
            )
        )
    );

    final progressBar = Container(
       margin: EdgeInsets.only(top: 24.0),
       child: Visibility(
           visible: loadingShown,
           child: CircularProgressIndicator(),
       )
    );

    return Scaffold(
        appBar: AppBar(title: Text('Flutter Tweets')),
        body: Center(
            child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    title,
                    email,
                    password,
                    login,
                    signUp,
                    progressBar
                  ],
                )
            )
        )
    );
  }
}
