import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:fluttertweets/maps.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Flutter Tweets')),
        body: LoginForm()
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {

  var buttonsEnabled = false;

  var loadingShown = false;

  final emailTextController = TextEditingController();

  final passwordTextController = TextEditingController();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

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

  Future<FirebaseUser> _handleSignUp() async {
    final inputtedEmail = emailTextController.text.trim();
    final inputtedPassword = emailTextController.text.trim();
    print("Registering as $inputtedEmail / $inputtedPassword");
    final registerTask = firebaseAuth.createUserWithEmailAndPassword(email: inputtedEmail, password: inputtedPassword);
    return (await registerTask).user;
  }

  Future<FirebaseUser> _handleSignIn() async {
    final inputtedEmail = emailTextController.text.trim();
    final inputtedPassword = emailTextController.text.trim();
    print("Registering as $inputtedEmail / $inputtedPassword");
    final registerTask = firebaseAuth.signInWithEmailAndPassword(email: inputtedEmail, password: inputtedPassword);
    return (await registerTask).user;
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
              _handleSignIn()
                  .then((user) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Signed in as ${user.email}!"),
                    ));
                    setState(() {
                      loadingShown = false;
                    });
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MapsScreen()));
                  })
                  .catchError((e) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Failed to sign in: $e"),
                    ));
                    setState(() {
                      loadingShown = false;
                    });
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
            onPressed: buttonsEnabled ? () {
              _handleSignUp()
                  .then((user) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Registered as ${user.email}"),
                    ));
                  })
                  .catchError((e) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Failed to register: $e"),
                    ));
                  });
            } : null,
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

    return Center(
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
    );
  }
}
