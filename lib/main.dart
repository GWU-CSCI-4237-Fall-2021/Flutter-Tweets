import 'package:flutter/material.dart';
import 'login.dart';

/// Here's the entry point to our app
void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    /// Wrap our application in one that uses Material Design
    /// (as opposed to iOS's Cupertino or a roll-your-own design)
    ///
    /// The first screen of the app will be the LoginScreen.
    return MaterialApp(
      title: 'Flutter Tweets',
      home: LoginScreen(),
    );
  }
}