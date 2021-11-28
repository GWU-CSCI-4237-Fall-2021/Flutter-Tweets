import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'maps.dart';

/// Our LoginScreen is comprised of two major pieces:
///   - The title bar
///   - The actual login form
class LoginScreen extends StatelessWidget {
  /// Creates the UI.
  @override
  Widget build(BuildContext context) {
    final title = Container(
        margin: EdgeInsets.only(top: 16.0),
        child: Text("Login",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)));

    return Scaffold(
        appBar: AppBar(title: Text('Flutter Tweets')),
        body: Column(children: [title, LoginForm()]));
  }
}

/// The LoginForm part of the screen needs to keep track of state and update accordingly.
class LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginFormState();
}

/// Keeps track of whether buttons are enabled / disabled, whether the spinner should be
/// shown or not, and the text typed into the email / password fields. The UI updates
/// accordingly based on the current state of these values.
class LoginFormState extends State<LoginForm> {
  /// Controls whether the Login or Sign Up buttons are enabled.
  var buttonsEnabled = false;

  /// Controls whether our progress indicator is shown.
  var loadingShown = false;

  /// Receives text events to the email field.
  final TextEditingController emailTextController = TextEditingController();

  /// Receives text events to the password field.
  final TextEditingController passwordTextController = TextEditingController();

  /// Connection to Firebase Authentication.
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  /// Set up text watchers and restore credentials from preferences.
  @override
  void initState() {
    super.initState();
    // These are like Android's TextWatchers
    emailTextController.addListener(_updateButtonState);
    passwordTextController.addListener(_updateButtonState);

    _restoreCredentials();
  }

  @override
  void dispose() {
    // Unregister / cleanup the controllers after we're done with this screen state
    emailTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }

  /// Set [buttonsEnabled] based on whether both email & password fields are non-empty.
  void _updateButtonState() {
    final enabled = emailTextController.text.trim().isNotEmpty &&
        passwordTextController.text.trim().isNotEmpty;
    setState(() {
      buttonsEnabled = enabled;
    });
  }

  /// Async task to Firebase to register a new user.
  Future<UserCredential> _handleSignUp() {
    final inputtedEmail = emailTextController.text.trim();
    final inputtedPassword = emailTextController.text.trim();

    return firebaseAuth.createUserWithEmailAndPassword(
        email: inputtedEmail, password: inputtedPassword);
  }

  /// Async task to Firebase to sign in using credentials.
  Future<UserCredential> _handleSignIn() {
    final inputtedEmail = emailTextController.text.trim();
    final inputtedPassword = emailTextController.text.trim();

    return firebaseAuth.signInWithEmailAndPassword(
        email: inputtedEmail, password: inputtedPassword);
  }

  /// Creates the UI, based on the current state.
  @override
  Widget build(BuildContext context) {
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
        margin: EdgeInsets.only(top: 24.0),
        child: _buildAuthButton(_handleSignIn, "Login"));

    final signUp = _buildAuthButton(_handleSignUp, "Sign Up");

    final progressBar = Container(
        margin: EdgeInsets.only(top: 24.0),
        child: Visibility(
          visible: loadingShown,
          child: CircularProgressIndicator(),
        ));

    return Center(
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [email, password, login, signUp, progressBar],
            )));
  }

  /// Helper function to build the Login & Sign Up buttons, since they
  /// both behave the same, except for which Firebase Auth function they call.
  Container _buildAuthButton(
      Future<UserCredential> Function() authFunction,
      String description
  ) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 24.0),
        width: double.infinity,
        child: ElevatedButton(
            // Setting the onPressed listener to null disables the button
            // Using the ternary operator here: <condition> ? <true> : <false>
            onPressed: buttonsEnabled && !loadingShown
                ? () {
                    _handleAuthButtonClicked(authFunction, description);
                  }
                : null,
            style: ElevatedButton.styleFrom(onPrimary: Colors.white),
            child: Center(child: Text(description.toUpperCase()))));
  }

  void _handleAuthButtonClicked(
      Future<UserCredential> Function() authFunction,
      String description
  ) {
    // Display the loading spinner...
    setState(() {
      loadingShown = true;
    });
    // Wait for the Firebase Auth result...
    authFunction().then((authResult) {
      // If successful show a short message...
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Successful $description: ${authResult.user?.email}!"),
      ));

      // Hide the loading spinner...
      setState(() {
        loadingShown = false;
      });

      // Save credentials to SharedPrefs...
      _saveCredentials();

      // Go to the Maps screen
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapsScreen())
      );
    }).catchError((e) {
      // If failed show a short message...
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed $description: $e"),
      ));

      // Hide the loading spinner
      setState(() {
        loadingShown = false;
      });
    });
  }

  /// Saves email / password to SharedPreferences.
  void _saveCredentials() async {
    final inputtedEmail = emailTextController.text.trim();
    final inputtedPassword = emailTextController.text.trim();

    // SharedPreferences is loaded asynchronously
    final prefs = await SharedPreferences.getInstance();

    // Save values to prefs
    prefs.setString("email", inputtedEmail);
    prefs.setString("password", inputtedPassword);
  }

  /// Restores email / password from SharedPreferences.
  void _restoreCredentials() async {
    // SharedPreferences is loaded asynchronously
    final prefs = await SharedPreferences.getInstance();

    // Restore values from prefs
    emailTextController.text = prefs.getString("email") ?? "";
    passwordTextController.text = prefs.getString("password") ?? "";
  }
}
