import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:fluttertweets/maps.dart';

/// Our LoginScreen is comprised of two major pieces:
///   - The title bar
///   - The actual login form
class LoginScreen extends StatelessWidget {
  /// Creates the UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Flutter Tweets')), body: LoginForm());
  }
}

/// The LoginForm part of the screen needs to keep track of state and update accordingly.
class LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginFormState();
}

/// Keeps track of whether buttons are enabled / disabled, whether the spinner should be
/// shown or not, and the text typed into the email / password fields. The UI updates
/// accordingly based on the current state of these values.
class _LoginFormState extends State<LoginForm> {
  /// Controls whether the Login or Sign Up buttons are enabled.
  var buttonsEnabled = false;

  /// Controls whether our progress indicator is shown.
  var loadingShown = false;

  /// Receives text events to the email field.
  final emailTextController = TextEditingController();

  /// Receives text events to the password field.
  final passwordTextController = TextEditingController();

  /// Connection to Firebase Authentication.
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // These are like Android's TextWatchers
    emailTextController.addListener(updateButtonState);
    passwordTextController.addListener(updateButtonState);
  }

  @override
  void dispose() {
    // Unregister / cleanup the controllers after we're done with this screen state
    emailTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }

  /// Set [buttonsEnabled] based on whether both email & password fields are non-empty.
  void updateButtonState() {
    final enabled = emailTextController.text.trim().isNotEmpty &&
        passwordTextController.text.trim().isNotEmpty;
    setState(() {
      buttonsEnabled = enabled;
    });
  }

  /// Async task to Firebase to register a new user.
  Future<FirebaseUser> _handleSignUp() async {
    final inputtedEmail = emailTextController.text.trim();
    final inputtedPassword = emailTextController.text.trim();

    final Future<AuthResult> registerTask =
        firebaseAuth.createUserWithEmailAndPassword(
            email: inputtedEmail, password: inputtedPassword);
    return (await registerTask).user;
  }

  /// Async task to Firebase to sign in using credentials.
  Future<FirebaseUser> _handleSignIn() async {
    final inputtedEmail = emailTextController.text.trim();
    final inputtedPassword = emailTextController.text.trim();

    final loginTask = firebaseAuth.signInWithEmailAndPassword(
        email: inputtedEmail, password: inputtedPassword);
    return (await loginTask).user;
  }

  /// Creates the UI, based on the current state.
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
        margin: EdgeInsets.only(top: 16.0),
        child: _buildAuthButton(_handleSignIn, "sign in")
    );

    final signUp = _buildAuthButton(_handleSignUp, "sign up");

    final progressBar = Container(
        margin: EdgeInsets.only(top: 24.0),
        child: Visibility(
          visible: loadingShown,
          child: CircularProgressIndicator(),
        ));

    return Center(
        child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [title, email, password, login, signUp, progressBar],
            )));
  }

  /// Helper function to build the Login & Sign Up buttons, since they
  /// both behave the same, except for which Firebase Auth function they call.
  Container _buildAuthButton(
      Future<FirebaseUser> Function() authFunction, String description) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 24.0),
        child: RaisedButton(
            // Setting the onPressed listener to null disables the button
            // Using the ternary operator here: <condition> ? <true> : <false>
            onPressed: buttonsEnabled && !loadingShown
                ? () {
                    // Display the loading spinner...
                    setState(() {
                      loadingShown = true;
                    });
                    // Wait for the Firebase Auth result...
                    authFunction().then((user) {
                      // If successful show a short message...
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content:
                            Text("Successful $description: ${user.email}!"),
                      ));

                      // Hide the loading spinner...
                      setState(() {
                        loadingShown = false;
                      });

                      // Go to the Maps screen
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MapsScreen()));
                    }).catchError((e) {
                      // If failed show a short message...
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("Failed $description: $e"),
                      ));

                      // Hide the loading spinner
                      setState(() {
                        loadingShown = false;
                      });
                    });
                  }
                : null,
            child: SizedBox(
                width: double.infinity,
                child: Center(child: Text(description.toUpperCase())))));
  }
}
